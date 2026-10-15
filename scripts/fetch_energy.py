#!/usr/bin/env python3
"""Gera docs/data/energy.json com a bandeira tarifária vigente e a tarifa
residencial (TE+TUSD) de cada distribuidora, a partir dos Dados Abertos da
ANEEL. Roda semanalmente pelo GitHub Actions; o app lê o JSON pelo GitHub."""

import csv
import io
import json
import urllib.parse
import urllib.request
from datetime import date

BASE = "https://dadosabertos.aneel.gov.br"
RESOURCE_TARIFAS = "fcf2906c-7c32-4b9b-a637-054e7a5234f4"
URL_BANDEIRA = (
    BASE
    + "/dataset/7f43a020-6dc5-44b8-80b4-d97eaa94436c/resource/"
    + "0591b8f6-fe54-437b-b72b-1aa2efd46e42/download/bandeira-tarifaria-acionamento.csv"
)


def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": "GreeApp/1.0"})
    with urllib.request.urlopen(req, timeout=120) as r:
        return r.read()


def bandeira():
    raw = get(URL_BANDEIRA).decode("utf-8", "replace")
    rows = list(csv.reader(io.StringIO(raw), delimiter=";"))
    best = None
    for row in rows[1:]:
        if len(row) < 4:
            continue
        comp = row[1].strip()
        if best is None or comp > best[0]:
            best = (comp, row[2].strip(), row[3].strip())
    # valor oficial em R$/MWh -> R$/kWh
    val = best[2].replace(".", "").replace(",", ".") if best else "0"
    return {
        "competencia": best[0] if best else None,
        "name": best[1] if best else "Verde",
        "surcharge_per_kwh": round(float(val or 0) / 1000, 5),
    }


def tarifas():
    """Puxa as linhas mais recentes (sort desc) e fica com a residencial padrão."""
    params = urllib.parse.urlencode(
        {
            "resource_id": RESOURCE_TARIFAS,
            "filters": json.dumps(
                {
                    "DscClasse": "Residencial",
                    "DscBaseTarifaria": "Tarifa de Aplicação",
                    "DscModalidadeTarifaria": "Convencional",
                },
                ensure_ascii=False,
            ),
            "fields": "SigAgente,DscSubClasse,DscDetalhe,NomPostoTarifario,VlrTUSD,VlrTE",
            "sort": "DatInicioVigencia desc",
            "limit": "5000",
        }
    )
    data = json.loads(get(f"{BASE}/api/3/action/datastore_search?{params}"))
    out = {}
    for r in data["result"]["records"]:
        if r.get("DscSubClasse") != "Residencial":
            continue
        if r.get("DscDetalhe") != "Não se aplica" or r.get("NomPostoTarifario") != "Não se aplica":
            continue
        agente = r["SigAgente"].strip()
        if agente in out:
            continue
        tusd = float(r["VlrTUSD"].replace(".", "").replace(",", ".") or 0)
        te = float(r["VlrTE"].replace(".", "").replace(",", ".") or 0)
        out[agente] = round((tusd + te) / 1000, 5)  # R$/MWh -> R$/kWh
    return out


def main():
    doc = {
        "updated": date.today().isoformat(),
        "source": "ANEEL Dados Abertos",
        "flag": bandeira(),
        "tariffs": tarifas(),
    }
    path = "docs/data/energy.json"
    with open(path, "w", encoding="utf-8") as f:
        json.dump(doc, f, ensure_ascii=False, indent=1, sort_keys=True)
    print(f"{path}: bandeira {doc['flag']['name']} ({doc['flag']['competencia']}), "
          f"{len(doc['tariffs'])} distribuidoras")


if __name__ == "__main__":
    main()
