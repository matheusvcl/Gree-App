import 'package:flutter/material.dart';

/* Card com swipe próprio (o Dismissible do Flutter joga o card para fora da
   tela e a borda some). O card ESPEMPE e o botão da ação — quadrado — desliza
   de trás dele; nunca sai da tela. Solta além de 40px dispara a ação
   (direita = editar, esquerda = excluir). */
class SwipeCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  const SwipeCard({
    super.key,
    required this.child,
    required this.onEdit,
    required this.onDelete,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> {
  double dx = 0;

  @override
  Widget build(BuildContext context) {
    final editP = (dx / 72).clamp(0.0, 1.0);
    final delP = (-dx / 72).clamp(0.0, 1.0);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onLongPressStart: widget.onLongPress != null ? (_) => widget.onLongPress!() : null,
      onHorizontalDragUpdate: (d) => setState(() => dx = (dx + d.delta.dx).clamp(-72.0, 72.0)),
      onHorizontalDragEnd: (_) {
        if (dx.abs() > 40) {
          final isEdit = dx > 0;
          setState(() => dx = isEdit ? 72 : -72);
          Future.delayed(const Duration(milliseconds: 280), () {
            if (!mounted) return;
            setState(() => dx = 0);
            if (isEdit) {
              widget.onEdit();
            } else {
              widget.onDelete();
            }
          });
        } else {
          setState(() => dx = 0);
        }
      },
      onHorizontalDragCancel: () => setState(() => dx = 0),
      child: ClipRect(
        child: Row(children: [
          if (dx > 0)
            SizedBox(width: dx, child: _panel(Icons.edit_rounded, const Color(0xFF4EA8FF), editP)),
          Expanded(child: widget.child),
          if (dx < 0)
            SizedBox(width: -dx, child: _panel(Icons.delete_rounded, const Color(0xFFFF4D4F), delP)),
        ]),
      ),
    );
  }

  /* botão quadrado (56×56) centralizado no painel — igual nos dois lados */
  Widget _panel(IconData icon, Color color, double p) {
    return Center(
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18)),
        child: Center(
          child: Opacity(
            opacity: p.clamp(0.0, 1.0),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: .5, end: 1),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutBack,
              builder: (_, v, child) => Transform.scale(scale: p > .2 ? v : 1, child: child),
              child: Icon(icon, color: Colors.white, size: 21),
            ),
          ),
        ),
      ),
    );
  }
}
