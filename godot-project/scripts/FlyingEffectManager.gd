extends Node
class_name FlyingEffectManager

func play_jump(node: CanvasItem) -> void:
	if node == null:
		return
	node.scale = Vector2(0.9, 0.9)
	var tween := node.create_tween()
	tween.tween_property(node, "scale", Vector2(1.1, 1.1), 0.1)
	tween.tween_property(node, "scale", Vector2.ONE, 0.1)

func play_coin_feedback(label: Label, delta_text: String) -> void:
	if label == null:
		return
	label.text = delta_text
	label.modulate = Color("#f1c40f")
	var tween := label.create_tween()
	tween.tween_property(label, "position:y", label.position.y - 20.0, 0.35)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.35)
