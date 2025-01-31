extends Label

@onready var helper_text_node = self

func _ready():
	# Connect the signal that gets fired on every focus change
	get_viewport().connect("gui_focus_changed", _on_focus_changed)

func _on_focus_changed(selected_element:Control) -> void:
	if selected_element != null and selected_element.has_meta("rekku") and class_functions.rekku_state == true:
		#helper_text_node.text = selected_element.get_meta("rekku")
		%pop_rtl.visible = true
		%pop_rtl.text = selected_element.get_meta("rekku")
	elif selected_element != null and selected_element.has_meta("description") and class_functions.rekku_state == false:
		%pop_rtl.visible = true
		var text_newline : String = selected_element.get_meta("description") as String
		text_newline = text_newline.replace("\\n", "\n")
		%pop_rtl.text = text_newline

#func replace_newline(text: String) -> String:
	#return text.replace("\n", "\n")
