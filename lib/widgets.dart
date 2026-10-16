import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'theme.dart';

/* ---------- topbar ---------- */
class TopBar extends StatelessWidget {
  final String title;
  final bool center;
  final VoidCallback? onBack;
  const TopBar({super.key, required this.title, this.center = false, this.onBack});

  @override
  Widget build(BuildContext context) {
    final p = context.palette();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: onBack == null
                  ? const SizedBox(width: 36, height: 36)
                  : _IconBtn(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack!),
            ),
            Align(
              alignment: center ? Alignment.center : Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: center ? 0 : 44),
                child: Text(title,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: p.text, letterSpacing: .1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: p.surface2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.line),
        ),
        child: Icon(icon, size: 15, color: p.text),
      ),
    );
  }
}

/* ---------- card / título ---------- */
class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette();
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 22, 2, 10),
      child: Text(text.toUpperCase(),
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: p.dim, letterSpacing: .7)),
    );
  }
}

/* título de seção com ação à direita (ex.: o + de novos itens) */
class SectionTitleAction extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final String label;
  const SectionTitleAction(this.text, {super.key, required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    final p = context.palette();
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 22, 2, 10),
      child: Row(children: [
        Expanded(
          child: Text(text.toUpperCase(),
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: p.dim, letterSpacing: .7)),
        ),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(10), border: Border.all(color: p.line)),
            child: const Icon(Icons.add_rounded, size: 17, color: AppColors.accent),
          ),
        ),
      ]),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final bool selected;
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.margin, this.selected = false});

  @override
  Widget build(BuildContext context) {
    final p = context.palette();
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      padding: padding,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? AppColors.accent : p.line, width: 1),
      ),
      child: child,
    );
  }
}

/* ---------- chips ---------- */
class AppChip extends StatelessWidget {
  final String label;
  final bool on;
  final bool white;
  final bool ghost;
  final Widget? icon;
  final VoidCallback? onTap;
  final bool small;
  const AppChip({super.key, required this.label, this.on = false, this.white = false, this.ghost = false, this.icon, this.onTap, this.small = false});

  @override
  Widget build(BuildContext context) {
    final p = context.palette();
    Color bg = p.surface, fg = p.dim, bd = p.line;
    if (white) {
      bg = AppColors.white;
      fg = const Color(0xFF101316);
      bd = AppColors.white;
    } else if (ghost) {
      bg = p.surface2;
      fg = p.text;
      bd = p.line;
    } else if (on) {
      bg = p.text;
      fg = p.bg;
      bd = p.text;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: small ? 11 : 15, vertical: small ? 6 : 8),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999), border: Border.all(color: bd)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[icon!, const SizedBox(width: 5)],
            Text(label,
                style: TextStyle(fontSize: small ? 11.5 : 13.5, fontWeight: FontWeight.w500, color: fg)),
          ]),
        ),
      ),
    );
  }
}

/* ---------- switch ---------- */
class AppSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const AppSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final p = context.palette();
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 52,
        height: 31,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? AppColors.accent : p.surface2,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: value ? AppColors.accent : p.line),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              color: value ? Colors.white : p.dim,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

/* ---------- barra de ações flutuante ---------- */
class ActionButton {
  final String label;
  final VoidCallback onTap;
  final bool ghost;
  final bool danger;
  const ActionButton(this.label, this.onTap, {this.ghost = false, this.danger = false});
}

class ActionBar extends StatelessWidget {
  final List<ActionButton> actions;
  final bool bare;
  const ActionBar({super.key, required this.actions, this.bare = false});

  @override
  Widget build(BuildContext context) {
    final p = context.palette();
    return Container(
      padding: bare ? EdgeInsets.zero : const EdgeInsets.all(6),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      decoration: bare
          ? null
          : BoxDecoration(
              color: p.surface.withValues(alpha: .82),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: p.line),
            ),
      child: Row(
        children: [
          for (final (i, a) in actions.indexed)
            if (i > 0) ...[
              const SizedBox(width: 10),
              Expanded(child: _actionButton(a, p)),
            ] else
              Expanded(child: _actionButton(a, p)),
        ],
      ),
    );
  }

  Widget _actionButton(ActionButton a, AppPalette p) {
    return GestureDetector(
      onTap: a.onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: a.danger
              ? AppColors.danger
              : a.ghost
                  ? p.surface2
                  : AppColors.accent,
          borderRadius: BorderRadius.circular(22),
          border: a.ghost ? Border.all(color: p.line) : null,
        ),
        alignment: Alignment.center,
        child: Text(a.label,
            style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: a.ghost ? p.text : Colors.white)),
      ),
    );
  }
}

/* ---------- modal de confirmação ---------- */
Future<bool> showConfirm(BuildContext context,
    {required String title, required String text, String okLabel = 'Confirmar', bool danger = true}) async {
  final p = context.palette();
  final r = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black54,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 302,
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: p.line)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.text)),
          const SizedBox(height: 8),
          Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: p.dim, height: 1.6)),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx, false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                      color: p.surface2,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: p.line)),
                  alignment: Alignment.center,
                  child: Text('Cancelar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.text)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx, true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                      color: danger ? AppColors.danger : AppColors.accent, borderRadius: BorderRadius.circular(16)),
                  alignment: Alignment.center,
                  child: Text(okLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ),
          ]),
        ]),
      ),
    ),
  );
  return r ?? false;
}

/* ---------- toast ---------- */
void showToast(BuildContext context, String msg) {
  final p = context.palette();
  final entry = OverlayEntry(
    builder: (_) => Positioned(
      bottom: 110,
      left: 0,
      right: 0,
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          builder: (_, v, child) => Opacity(opacity: v, child: child),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: p.line),
            ),
            child: Text(msg,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: p.text,
                    decoration: TextDecoration.none)), // bloqueia sublinhado herdado (linha amarela)
          ),
        ),
      ),
    ),
  );
  Overlay.of(context).insert(entry);
  Future.delayed(const Duration(milliseconds: 1900), () => entry.remove());
}

            /* ---------- QR do convite: o ícone vira o QR ao tocar ---------- */
            class InviteQr extends StatefulWidget {
            final String code;
            const InviteQr({super.key, required this.code});

            @override
            State<InviteQr> createState() => _InviteQrState();
            }

            class _InviteQrState extends State<InviteQr> {
            bool open = false;

            @override
            Widget build(BuildContext context) {
            final p = context.palette();
            return GestureDetector(
            onTap: () => setState(() => open = !open),
            child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
            color: p.surface2,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.line),
            ),
            child: open
              ? Column(children: [
                  QrImageView(
                    data: widget.code,
                    size: 168,
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.all(10),
                  ),
                  const SizedBox(height: 8),
                  Text('Mostre para a pessoa escanear com a câmera',
                      textAlign: TextAlign.center, style: TextStyle(fontSize: 10.5, color: p.dim)),
                ])
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.qr_code_2_rounded, size: 18, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text('Gerar QR code',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: p.text)),
                ]),
            ),
            );
            }
            }
