GDPC                `                                                                         T   res://.godot/exported/133200997/export-048b18d952c3bbf550794e76581ef7b1-theme.res   �      V       ��D���8ׇ���ȓ%    P   res://.godot/exported/133200997/export-3070c538c03ee49b7677ff960a3f5195-main.scn�f      I      �RWN��S��S�i\D9�    P   res://.godot/exported/133200997/export-7c047d1aa4f40ea8d261696e6c240724-tool.scn�A      \      W-��*���L �0    ,   res://.godot/global_script_class_cache.cfg  �t             ��Р�8���8~$}P�    D   res://.godot/imported/icon.svg-218a8f2b3041327d8a5756f3a245f83b.ctex T            ：Qt�E�cO���       res://.godot/uid_cache.bin  `x      �       �\�u��*) 筒�T       res://addons/cba/config.json        �       �/�W�����А���       res://addons/cba/plugin.gd  �       �      �j��2i���"���    $   res://addons/cba/theme.tres.remap   0s      b       "mZHL
2ȱ�0c!�       res://addons/cba/tool.gd�;      �      ��M#��5�a��2	�        res://addons/cba/tool.tscn.remap�s      a       ֋�wAd��6�q|,�       res://icon.svg  �t      �      k����X3Y���f       res://icon.svg.import    a      �       z9���c�+��"�       res://main.gd   �a      �      k¥F6�{4�.�2���       res://main.tscn.remap   t      a       �J�Sw� ������       res://project.binary�x      �      ��x�4�݂6z�A��P4        {
	"bg_modulate": "999999b0",
	"filter": 0,
	"image": "C:/Users/Computer/Documents/Godot/Flow-Chart/addons/cba/images/landscape_blur.png",
	"stretch": 0,
	"ui_color": "000000c8"
}             @tool
extends EditorPlugin

var base:Control
var editor_settings:EditorSettings

const TOOL = preload("res://addons/cba/tool.tscn")
var settings:Dictionary = {}
var bg:TextureRect
var tool:Window
var theme:Theme

var accent_color:Color

func _disable_plugin():
	bg.queue_free()
	editor_settings.set("interface/theme/custom_theme", "")
	editor_settings.set("interface/theme/preset", "Default")
	remove_tool_menu_item("Backgrounds")

func _enter_tree():
	#Benchmark.start("init")
	if not Engine.is_editor_hint(): return
	
	base = EditorInterface.get_base_control()
	editor_settings = EditorInterface.get_editor_settings()
	editor_settings.settings_changed.connect(func():
		for setting in editor_settings.get_changed_settings():
			_setting_changed(setting)
	)
	bg = TextureRect.new()
	bg.name = "Editor Background"
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	base.add_child.call_deferred(bg)
	# move it to the top of the tree so it's behind all the UI
	base.move_child.call_deferred(bg, 0)
	await bg.ready
	
	theme = preload("res://addons/cba/theme.tres")
	if editor_settings.get("interface/theme/custom_theme") != "res://addons/cba/theme.tres":
		editor_settings.set("interface/theme/custom_theme", "res://addons/cba/theme.tres")
	if editor_settings.get("interface/theme/preset") != "Custom":
		editor_settings.set("interface/theme/preset", "Custom")
	
	await base.get_tree().physics_frame
	load_settings()
	
	add_tool_menu_item("Backgrounds", func():
		if is_instance_valid(tool): printerr("There is already a background picker window open."); return
		tool = TOOL.instantiate()
		tool.main = self
		base.add_child(tool)
		tool.start()
		tool.popup_centered()
	)
	#Benchmark.end("init")

func change_setting(value:Variant, setting:String, update_ui:bool = false, update_setting:bool = true):
	var is_prev_ready := is_instance_valid(tool)
	match setting:
		"image":
			var img := load_image(value)
			if is_prev_ready: tool.preview.texture = img
			if update_setting: bg.texture = img
		"stretch":
			if update_setting: bg.stretch_mode = value
			if is_prev_ready:
				tool.preview.stretch_mode = value
				if update_ui:
					tool.get_node("HBoxContainer/VBoxContainer/stretch mode").select(value)
		"filter":
			if update_setting: bg.texture_filter = value
			if is_prev_ready:
				tool.preview.texture_filter = value
				if update_ui:
					tool.get_node("HBoxContainer/VBoxContainer/filter mode").select(value)
		"ui_color":
			if is_prev_ready:
				if update_ui:
					value = Color(settings["ui_color"])
					tool.get_node("HBoxContainer/VBoxContainer2/ui_color").color = value
				else:
					value = tool.get_node("HBoxContainer/VBoxContainer2/ui_color").color
			if not update_ui && update_setting:
				if value == Color(settings["ui_color"]): return
				change_theme_color(value)
				settings["ui_color"] = value.to_html()
			value = null
		"bg_modulate":
			if value is String: value = Color(value)
			if update_setting: bg.modulate = value
			if is_prev_ready:
				tool.preview.modulate = value
				if update_ui:
					tool.get_node("HBoxContainer/VBoxContainer2/bg_modulate").color = value
			value = value.to_html()
	if value != null: settings[setting] = value

func load_image(path:String) -> Texture2D:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: printerr("file not found: ", path); return
	var image = Image.load_from_file(path)
	var out = ImageTexture.create_from_image(image)
	return out

func load_settings():
	if FileAccess.file_exists("res://addons/cba/config.json"):
		var file := FileAccess.open("res://addons/cba/config.json", FileAccess.READ)
		if file == null:
			file = FileAccess.open("res://addons/cba/config.json", FileAccess.WRITE_READ)
			assert(file != null, "Error opening file.")
			return
		else:
			settings = JSON.parse_string(file.get_as_text())
			file.close()
	else:
		var file := FileAccess.open("res://addons/cba/config.json", FileAccess.WRITE)
		var defaults := {
			"filter": 0.0,
			"image": ProjectSettings.globalize_path("res://addons/cba/images/default.png"),
			"stretch": 1,
			"ui_color": "00000088",
			"bg_modulate": "ffffffb0",
		}
		file.store_string(JSON.stringify(defaults, "\t"))
		settings = defaults
		file.close()
	for s in settings.keys():
		change_setting(settings[s], s, true)

func save_settings():
	var file := FileAccess.open("res://addons/cba/config.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(settings, "\t"))

func _setting_changed(setting:String):
	match setting:
		"interface/theme/accent_color":
			change_theme_color(Color(settings["ui_color"]))

func change_theme_color(col:Color):
	#Benchmark.start("change theme color")
	
	accent_color = editor_settings.get_setting("interface/theme/accent_color")
	
	var controls_list = get_all_controls([base])

	var col2 := Color(col, col.a/2.0)
	var col3 := Color(col, min(col.a/col.v, col.a/4.0))
	change_color("EditorStyles", "Background", col)
	change_color("EditorStyles", "BottomPanel", col)
	change_color("EditorStyles", "BottomPanelDebuggerOverride", col)
	change_color("EditorStyles", "Content", col)
	change_color("EditorStyles", "LaunchPadNormal", col)
	
	change_color("TabContainer", "panel", col)
	change_color("TabContainer", "tab_selected", col, accent_color)
	change_color("TabContainer", "tab_unselected", col2)
	change_color("TabContainer", "tab_hovered", col2)
	
	change_color("TabBar", "tab_selected", col, accent_color)
	change_color("TabBar", "tab_unselected", col2)
	change_color("TabBar", "tab_hovered", col2)
	
	change_color("TabContainerOdd", "tab_selected", col, accent_color)
	change_color("TabContainerOdd", "panel", col2)
	
	# bordered
	change_color("Button", "normal", col3)
	change_color("MenuButton", "normal", col3)
	change_color("OptionButton", "normal", col3)
	change_color("RichTextLabel", "normal", col3)
	change_color("LineEdit", "normal", col3)
	change_color("LineEdit", "read_only", col3)
	change_color("EditorProperty", "child_bg", col3)
	
	change_color("EditorInspectorCategory", "bg", col2)
	
	# fix to old values showing up in transparent preview
	change_color("LineEdit", "focus", Color.BLACK)
	
	# trigger an update
	theme.get_stylebox("Background", "EditorStyles").emit_changed()
	
	#Benchmark.end("change theme color")

func get_all_controls(nodes:Array[Node]) -> Array[Node]:
	var out:Array[Node] = []
	for node in nodes:
		if node is Control: out.append(node)
		var children := node.get_children() as Array[Node]
		out += get_all_controls(children)
	return out

func change_color(type:String, name:String, col:Color, border = null):
	var box:StyleBoxFlat = theme.get_stylebox(name, type)
	box.set_block_signals(true)
	box.bg_color = col
	if border != null: 
		box.border_color = border
	box.set_block_signals(false)
              RSRC                    Theme            ��������                                            E      resource_local_to_scene    resource_name    content_margin_left    content_margin_top    content_margin_right    content_margin_bottom 	   bg_color    draw_center    skew    border_width_left    border_width_top    border_width_right    border_width_bottom    border_color    border_blend    corner_radius_top_left    corner_radius_top_right    corner_radius_bottom_right    corner_radius_bottom_left    corner_detail    expand_margin_left    expand_margin_top    expand_margin_right    expand_margin_bottom    shadow_color    shadow_size    shadow_offset    anti_aliasing    anti_aliasing_size    script    default_base_scale    default_font    default_font_size    Button/styles/normal    CodeEdit/styles/normal "   EditorInspectorCategory/styles/bg    EditorProperty/styles/child_bg    EditorStyles/styles/Background     EditorStyles/styles/BottomPanel 0   EditorStyles/styles/BottomPanelDebuggerOverride *   EditorStyles/styles/CanvasItemInfoOverlay    EditorStyles/styles/Content &   EditorStyles/styles/ContextualToolbar "   EditorStyles/styles/DebuggerPanel &   EditorStyles/styles/DictionaryAddItem    EditorStyles/styles/Focus $   EditorStyles/styles/LaunchPadNormal    EditorStyles/styles/MenuPanel $   EditorStyles/styles/PanelForeground !   EditorStyles/styles/ScriptEditor &   EditorStyles/styles/ScriptEditorPanel    ItemList/styles/panel    LineEdit/styles/focus    LineEdit/styles/normal    LineEdit/styles/read_only    MenuButton/styles/normal    OptionButton/styles/normal    RichTextLabel/styles/normal    TabBar/styles/tab_hovered    TabBar/styles/tab_selected    TabBar/styles/tab_unselected    TabContainer/styles/panel     TabContainer/styles/tab_hovered !   TabContainer/styles/tab_selected #   TabContainer/styles/tab_unselected &   TabContainer/styles/tabbar_background    TabContainerOdd/styles/panel $   TabContainerOdd/styles/tab_selected    Tree/styles/panel     %      local://StyleBoxFlat_6rrxc �         local://StyleBoxEmpty_jw7he �         local://StyleBoxFlat_x4bf7 �         local://StyleBoxFlat_qm4uc          local://StyleBoxFlat_kmfvt �         local://StyleBoxFlat_1tn6y �         local://StyleBoxFlat_mfvec �         local://StyleBoxFlat_yxe5q          local://StyleBoxFlat_wrepn H         local://StyleBoxEmpty_4qoyy }         local://StyleBoxFlat_bae5w �         local://StyleBoxFlat_hqa07 �         local://StyleBoxFlat_jbgu4          local://StyleBoxFlat_7xbe2 :         local://StyleBoxFlat_eag6m �         local://StyleBoxFlat_crty7          local://StyleBoxEmpty_nn8ly E         local://StyleBoxFlat_yi1o1 c         local://StyleBoxEmpty_ebp5u �         local://StyleBoxFlat_7l2sj �         local://StyleBoxFlat_cbyhm �         local://StyleBoxFlat_cjlww �         local://StyleBoxFlat_xi4cy ]         local://StyleBoxFlat_thgut "         local://StyleBoxFlat_4rkfj �         local://StyleBoxFlat_jlb1y �         local://StyleBoxFlat_lvnv7 q         local://StyleBoxFlat_ve3ye          local://StyleBoxFlat_kcmrn �         local://StyleBoxFlat_e473q T         local://StyleBoxFlat_gir5j �         local://StyleBoxFlat_th0sh �         local://StyleBoxFlat_og5m1          local://StyleBoxFlat_prlgo �         local://StyleBoxFlat_4n6md I         local://StyleBoxEmpty_c0v5a �         local://Theme_2tem0 �         StyleBoxFlat            �@        �@        �@        �@                  ��>	         
                                 ���>���>���>  �?                                                                StyleBoxEmpty             StyleBoxFlat            �@        �@        �@        �@                  ���>      s��>���>���>  �?                                                                StyleBoxFlat                      ��>         StyleBoxFlat                      ��?         StyleBoxFlat            �@        �@        �@        �@                  ��?                                                       StyleBoxFlat 	           �@                  �@        �@                  ��?                                     StyleBoxFlat          e?OZ ?o�`>  �?         StyleBoxFlat                      ��?         StyleBoxEmpty             StyleBoxFlat                                   StyleBoxFlat          UM8?�?B>  �?         StyleBoxFlat          �l`?���>��=>  �?         StyleBoxFlat             @                   @                            ��?                                                       StyleBoxFlat          ���>��%?��Q?             StyleBoxFlat              :?�>  �?         StyleBoxEmpty             StyleBoxFlat          ��?��?��?             StyleBoxEmpty             StyleBoxFlat                        �?         StyleBoxFlat            �@        �@        �@        �@                  ��>               ���=r�>��$>  �?                                              StyleBoxFlat            �@        �@        �@        �@                  ��>               ���=r�>��$>  �?                                              StyleBoxFlat            �@        �@        �@        �@                  ��>      �� ?�� ?�� ?  �?                                                                StyleBoxFlat            �@        �@        �@        �@                  ��>      �� ?�� ?�� ?  �?                                                                StyleBoxFlat            �@        �@        �@        �@                  ��>	         
                                 ���>���>���>  �?                                                                StyleBoxFlat 
           0A        �@        0A        �@                  ���>                                              StyleBoxFlat 
           0A        �@        0A        �@                  ��?
               ���>��?  �?  �?                            StyleBoxFlat 
           0A        �@        0A        �@                  ���>                                              StyleBoxFlat            �@        �@        �@        �@                  ��?      Z�f?��%?m�z>  �?                                              StyleBoxFlat 
           0A        �@        0A        �@                  ���>                                              StyleBoxFlat 
           0A        �@        0A        �@                  ��?
               ���>��?  �?  �?                            StyleBoxFlat 
           0A        �@        0A        �@                  ���>                                              StyleBoxFlat 
                                                                                                               StyleBoxFlat 
           �@        �@        �@        �@                  ���>                                              StyleBoxFlat 	           0A        �@        0A        �@                  ��?
               ���>��?  �?  �?                   StyleBoxEmpty             Theme %   !             "            #            $            %            &            '            (            )            *         	   +         
   ,            -            .            /            0            1            2            3            4            5            6            7            8            9            :            ;            <            =            >            ?            @            A             B         !   C         "   D         #         RSRC          @tool
extends Window

var preview:TextureRect

var main:EditorPlugin

func start():
	if not Engine.is_editor_hint(): queue_free(); return
	$"HBoxContainer/VBoxContainer/image picker".pressed.connect(_image_picker)
	$"HBoxContainer/VBoxContainer/stretch mode".item_selected.connect(main.change_setting.bind("stretch"))
	$"HBoxContainer/VBoxContainer/filter mode".item_selected.connect(main.change_setting.bind("filter"))
	#$HBoxContainer/VBoxContainer2/ui_alpha.value_changed.connect(main.change_setting.bind("ui_alpha")) # too laggy
	$HBoxContainer/VBoxContainer2/ui_color.popup_closed.connect(main.change_setting.bind(null, "ui_color"))
	$HBoxContainer/VBoxContainer2/bg_modulate.color_changed.connect(main.change_setting.bind("bg_modulate"))
	close_requested.connect(close)
	preview = $PanelContainer/TextureRect # thank you onready
	main.load_settings()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		close()

func close():
	main.save_settings()
	queue_free()

func _image_picker():
	var picker := EditorFileDialog.new()
	picker.close_requested.connect(queue_free)
	picker.file_selected.connect(main.change_setting.bind("image"))
	picker.size = Vector2(700, 500)
	picker.access = EditorFileDialog.ACCESS_FILESYSTEM
	picker.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	picker.filters = ["*.bmp, *.dds, *.exr, *.hdr, *.jpg, *.jpeg, *.png, *.tga, *.svg, *.svgz, *.webp; Supported Images"]
	add_child(picker)
	picker.popup_centered()
               RSRC                    PackedScene            ��������                                            '      resource_local_to_scene    resource_name    content_margin_left    content_margin_top    content_margin_right    content_margin_bottom 	   bg_color    draw_center    skew    border_width_left    border_width_top    border_width_right    border_width_bottom    border_color    border_blend    corner_radius_top_left    corner_radius_top_right    corner_radius_bottom_right    corner_radius_bottom_left    corner_detail    expand_margin_left    expand_margin_top    expand_margin_right    expand_margin_bottom    shadow_color    shadow_size    shadow_offset    anti_aliasing    anti_aliasing_size    script    default_base_scale    default_font    default_font_size    Button/font_sizes/font_size    Button/styles/normal     ColorPickerButton/styles/normal    Label/font_sizes/font_size    Panel/styles/panel 	   _bundled       Script    res://addons/cba/tool.gd ��������      local://StyleBoxFlat_l27jc �         local://StyleBoxEmpty_5s6hr t         local://StyleBoxFlat_p8vlj �         local://Theme_csmr1 �         local://PackedScene_apuig %         StyleBoxFlat            �@        �@      ���>���>��\>  �?	         
                                 ��0?��0?��0?  �?                  ��:?                  StyleBoxEmpty             StyleBoxFlat          ��5>�S9>��\>  �?         Theme    !         "             #            $         %                     PackedScene    &      	         names "   <      Tool    title    initial_position    size 	   min_size 	   max_size    script    Window    Panel    anchors_preset    anchor_right    anchor_bottom    grow_horizontal    grow_vertical    theme    PanelContainer    clip_contents    offset_bottom    TextureRect    layout_mode    expand_mode    HBoxContainer    anchor_top    offset_left    offset_top    offset_right    size_flags_vertical    VBoxContainer    custom_minimum_size    image picker    size_flags_stretch_ratio    text    Button    stretch mode 
   clip_text    item_count    popup/item_0/text    popup/item_0/id    popup/item_1/text    popup/item_1/id    popup/item_2/text    popup/item_2/id    popup/item_3/text    popup/item_3/id    popup/item_4/text    popup/item_4/id    popup/item_5/text    popup/item_5/id    popup/item_6/text    popup/item_6/id    OptionButton    filter mode    VBoxContainer2    Label &   theme_override_constants/line_spacing    horizontal_alignment 	   ui_color    ColorPickerButton    Label2    bg_modulate    	   variants    ,         Chey's Background Addon       -   �  ^  -   �  ,                       �?                          ��         ����   '1h?      @   f��     �@   i TB             
     DC  /C
         B             Pick an image             Scale       Tile       Keep       Keep Centered       Keep Aspect             Keep Aspect Centered       Keep Aspect Covered             Nearest       Linear       Nearest Mipmap       Linear Mipmap       Nearest Mipmap Anisotropic       Linear Mipmap Anisotropic    ����   "   UI Color
(close picker to change) 
         �A      Background Modulate       node_count             nodes       ��������       ����                                                          ����   	      
                                                ����      	   	      
               
                                      ����                                 ����   	            
                                                                             ����                                 ����                                      2   !   ����      	                     "   	   #      $      %      &      '      (      )      *      +      ,      -      .      /      0       1   !              2   3   ����      	                     "   	   #   !   $   "   %      &   #   '      (   $   )      *   %   +      ,   &   -      .   '   /                    4   ����                         	       5   5   ����         6   (      )   7          	       9   8   ����      *                   	       5   :   ����            +   7          	       9   ;   ����      *                         conn_count              conns               node_paths              editable_instances              version             RSRC    GST2   �   �      ����               � �        �  RIFF�  WEBPVP8L�  /������!"2�H�m�m۬�}�p,��5xi�d�M���)3��$�V������3���$G�$2#�Z��v{Z�lێ=W�~� �����d�vF���h���ڋ��F����1��ڶ�i�엵���bVff3/���Vff���Ҿ%���qd���m�J�}����t�"<�,���`B �m���]ILb�����Cp�F�D�=���c*��XA6���$
2#�E.@$���A.T�p )��#L��;Ev9	Б )��D)�f(qA�r�3A�,#ѐA6��npy:<ƨ�Ӱ����dK���|��m�v�N�>��n�e�(�	>����ٍ!x��y�:��9��4�C���#�Ka���9�i]9m��h�{Bb�k@�t��:s����¼@>&�r� ��w�GA����ը>�l�;��:�
�wT���]�i]zݥ~@o��>l�|�2�Ż}�:�S�;5�-�¸ߥW�vi�OA�x��Wwk�f��{�+�h�i�
4�˰^91��z�8�(��yޔ7֛�;0����^en2�2i�s�)3�E�f��Lt�YZ���f-�[u2}��^q����P��r��v��
�Dd��ݷ@��&���F2�%�XZ!�5�.s�:�!�Њ�Ǝ��(��e!m��E$IQ�=VX'�E1oܪì�v��47�Fы�K챂D�Z�#[1-�7�Js��!�W.3׹p���R�R�Ctb������y��lT ��Z�4�729f�Ј)w��T0Ĕ�ix�\�b�9�<%�#Ɩs�Z�O�mjX �qZ0W����E�Y�ڨD!�$G�v����BJ�f|pq8��5�g�o��9�l�?���Q˝+U�	>�7�K��z�t����n�H�+��FbQ9���3g-UCv���-�n�*���E��A�҂
�Dʶ� ��WA�d�j��+�5�Ȓ���"���n�U��^�����$G��WX+\^�"�h.���M�3�e.
����MX�K,�Jfѕ*N�^�o2��:ՙ�#o�e.
��p�"<W22ENd�4B�V4x0=حZ�y����\^�J��dg��_4�oW�d�ĭ:Q��7c�ڡ��
A>��E�q�e-��2�=Ϲkh���*���jh�?4�QK��y@'�����zu;<-��|�����Y٠m|�+ۡII+^���L5j+�QK]����I �y��[�����(}�*>+���$��A3�EPg�K{��_;�v�K@���U��� gO��g��F� ���gW� �#J$��U~��-��u���������N�@���2@1��Vs���Ŷ`����Dd$R�":$ x��@�t���+D�}� \F�|��h��>�B�����B#�*6��  ��:���< ���=�P!���G@0��a��N�D�'hX�׀ "5#�l"j߸��n������w@ K�@A3�c s`\���J2�@#�_ 8�����I1�&��EN � 3T�����MEp9N�@�B���?ϓb�C��� � ��+�����N-s�M�  ��k���yA 7 �%@��&��c��� �4�{� � �����"(�ԗ�� �t�!"��TJN�2�O~� fB�R3?�������`��@�f!zD��%|��Z��ʈX��Ǐ�^�b��#5� }ى`�u�S6�F�"'U�JB/!5�>ԫ�������/��;	��O�!z����@�/�'�F�D"#��h�a �׆\-������ Xf  @ �q�`��鎊��M��T�� ���0���}�x^�����.�s�l�>�.�O��J�d/F�ě|+^�3�BS����>2S����L�2ޣm�=�Έ���[��6>���TъÞ.<m�3^iжC���D5�抺�����wO"F�Qv�ږ�Po͕ʾ��"��B��כS�p�
��E1e�������*c�������v���%'ž��&=�Y�ް>1�/E������}�_��#��|������ФT7׉����u������>����0����緗?47�j�b^�7�ě�5�7�����|t�H�Ե�1#�~��>�̮�|/y�,ol�|o.��QJ rmϘO���:��n�ϯ�1�Z��ը�u9�A������Yg��a�\���x���l���(����L��a��q��%`�O6~1�9���d�O{�Vd��	��r\�՜Yd$�,�P'�~�|Z!�v{�N�`���T����3?DwD��X3l �����*����7l�h����	;�ߚ�;h���i�0�6	>��-�/�&}% %��8���=+��N�1�Ye��宠p�kb_����$P�i�5�]��:��Wb�����������ě|��[3l����`��# -���KQ�W�O��eǛ�"�7�Ƭ�љ�WZ�:|���є9�Y5�m7�����o������F^ߋ������������������Р��Ze�>�������������?H^����&=����~�?ڭ�>���Np�3��~���J�5jk�5!ˀ�"�aM��Z%�-,�QU⃳����m����:�#��������<�o�����ۇ���ˇ/�u�S9��������ٲG}��?~<�]��?>��u��9��_7=}�����~����jN���2�%>�K�C�T���"������Ģ~$�Cc�J�I�s�? wڻU���ə��KJ7����+U%��$x�6
�$0�T����E45������G���U7�3��Z��󴘶�L�������^	dW{q����d�lQ-��u.�:{�������Q��_'�X*�e�:�7��.1�#���(� �k����E�Q��=�	�:e[����u��	�*�PF%*"+B��QKc˪�:Y��ـĘ��ʴ�b�1�������\w����n���l镲��l��i#����!WĶ��L}rեm|�{�\�<mۇ�B�HQ���m�����x�a�j9.�cRD�@��fi9O�.e�@�+�4�<�������v4�[���#bD�j��W����֢4�[>.�c�1-�R�����N�v��[�O�>��v�e�66$����P
�HQ��9���r�	5FO� �<���1f����kH���e�;����ˆB�1C���j@��qdK|
����4ŧ�f�Q��+�     [remap]

importer="texture"
type="CompressedTexture2D"
uid="uid://bb6op2t502qyx"
path="res://.godot/imported/icon.svg-218a8f2b3041327d8a5756f3a245f83b.ctex"
metadata={
"vram_texture": false
}
                extends Node2D

var bounds = Vector2i(50, 50)
var timer: float

@onready var tile_map: TileMap = $TileMap

const SLIDE_CHECK = Vector2i(1, 1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	timer += delta
	if timer > 0.1:
		timer = 0
		var all_tiles = tile_map.get_used_cells(0) + tile_map.get_used_cells(1)
		for cell in tile_map.get_used_cells(0):
			# this is really bad
			if !Vector2i(cell.x, cell.y + 1) in all_tiles:
				tile_map.set_cell(0, Vector2i(cell.x, cell.y + 1), 0, Vector2i.ZERO)
				tile_map.erase_cell(0, cell)
			else:
				var dir = randi_range(0, 1)
				dir *= 2
				dir -= 1
				for i in 2:
					dir *= -1
					if !cell + Vector2i(dir, 1) in all_tiles:
						tile_map.set_cell(0, Vector2i(cell.x + dir, cell.y + 1), 0, Vector2i.ZERO)
						tile_map.erase_cell(0, cell)
						break
						
						
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse_pos = tile_map.local_to_map(get_local_mouse_position() / tile_map.scale)
		tile_map.set_cell(0, mouse_pos, 0, Vector2i.ZERO)
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		var mouse_pos = tile_map.local_to_map(get_local_mouse_position() / tile_map.scale)
		tile_map.erase_cell(0, mouse_pos)
				
    RSRC                    PackedScene            ��������                                                  resource_local_to_scene    resource_name    texture    margins    separation    texture_region_size    use_texture_padding    0:0/0    0:0/0/script    script    0:0/0/modulate    tile_shape    tile_layout    tile_offset_axis 
   tile_size    uv_clipping 
   sources/0 
   sources/1    tile_proxies/source_level    tile_proxies/coords_level    tile_proxies/alternative_level 	   _bundled       Script    res://main.gd ��������
   Texture2D    res://icon.svg os����"   !   local://TileSetAtlasSource_62cg5 �      !   local://TileSetAtlasSource_wc86g d         local://TileSet_tep74 �         local://PackedScene_mrra2 ,         TileSetAtlasSource             Sand                -   �   �                   	         TileSetAtlasSource             Wall                -   �   �             
                    �?      	         TileSet       -   �   �                            	         PackedScene          	         names "         Node2D    script    TileMap    scale 	   tile_set    rendering_quadrant_size    format    layer_0/name    layer_0/navigation_enabled    layer_1/name    layer_1/navigation_enabled    layer_1/tile_data 	   Camera2D    anchor_mode    	   variants    
             
   }?5>}?5>            �               Sand              Walls     A                                                                                               	          
                                                                                                                                                                                                                                                                    	         
                                                                                                                                                                                                                !         "         #         $         %         &         '         (         )         *         +         ,         -         .         /         0         1         2          2         2         2         2         2         2         2         2         2 	        2 
        2         2         2         2         2         2         2         2         2         2         2         2         2         2         2         2         2         2                      node_count             nodes     +   ��������        ����                            ����	                                       	      
                              ����      	             conn_count              conns               node_paths              editable_instances              version       	      RSRC       [remap]

path="res://.godot/exported/133200997/export-048b18d952c3bbf550794e76581ef7b1-theme.res"
              [remap]

path="res://.godot/exported/133200997/export-7c047d1aa4f40ea8d261696e6c240724-tool.scn"
               [remap]

path="res://.godot/exported/133200997/export-3070c538c03ee49b7677ff960a3f5195-main.scn"
               list=Array[Dictionary]([])
     <svg height="128" width="128" xmlns="http://www.w3.org/2000/svg"><rect x="2" y="2" width="124" height="124" rx="14" fill="#363d52" stroke="#212532" stroke-width="4"/><g transform="scale(.101) translate(122 122)"><g fill="#fff"><path d="M105 673v33q407 354 814 0v-33z"/><path d="m105 673 152 14q12 1 15 14l4 67 132 10 8-61q2-11 15-15h162q13 4 15 15l8 61 132-10 4-67q3-13 15-14l152-14V427q30-39 56-81-35-59-83-108-43 20-82 47-40-37-88-64 7-51 8-102-59-28-123-42-26 43-46 89-49-7-98 0-20-46-46-89-64 14-123 42 1 51 8 102-48 27-88 64-39-27-82-47-48 49-83 108 26 42 56 81zm0 33v39c0 276 813 276 814 0v-39l-134 12-5 69q-2 10-14 13l-162 11q-12 0-16-11l-10-65H446l-10 65q-4 11-16 11l-162-11q-12-3-14-13l-5-69z" fill="#478cbf"/><path d="M483 600c0 34 58 34 58 0v-86c0-34-58-34-58 0z"/><circle cx="725" cy="526" r="90"/><circle cx="299" cy="526" r="90"/></g><g fill="#414042"><circle cx="307" cy="532" r="60"/><circle cx="717" cy="532" r="60"/></g></g></svg>
              �:����MC   res://addons/cba/theme.tres���[� R   res://addons/cba/tool.tscnos����"   res://icon.svg+��$e�d   res://main.tscn          ECFG      application/config/name      
   Pixel-Sand     application/run/main_scene         res://main.tscn    application/config/features(   "         4.2    GL Compatibility       application/config/icon         res://icon.svg     editor_plugins/enabled(   "         res://addons/cba/plugin.cfg #   rendering/renderer/rendering_method         gl_compatibility*   rendering/renderer/rendering_method.mobile         gl_compatibility      