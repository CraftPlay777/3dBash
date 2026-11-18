extends Node3D

const PLAYER_SPEED := 5.2
const JOY_RADIUS := 82.0
var joystick_active := false
var joystick_origin := Vector2.ZERO
var joystick_vector := Vector2.ZERO
var player: CharacterBody3D
var camera: Camera3D
var joystick_base: Control
var joystick_knob: Control
var status_label: Label

func _ready():
    build_world()
    build_player()
    build_ui()
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func build_world():
    var world_env := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    env.sky = Sky.new()
    var sky_mat := ProceduralSkyMaterial.new()
    sky_mat.sky_top_color = Color(0.18, 0.46, 0.82)
    sky_mat.sky_horizon_color = Color(0.72, 0.86, 0.98)
    sky_mat.ground_bottom_color = Color(0.23, 0.28, 0.20)
    sky_mat.ground_horizon_color = Color(0.58, 0.68, 0.57)
    env.sky.sky_material = sky_mat
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.68, 0.72, 0.78)
    env.ambient_light_energy = 0.7
    world_env.environment = env
    add_child(world_env)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48, -32, 0)
    sun.light_energy = 1.2
    sun.shadow_enabled = true
    add_child(sun)

    var ground := StaticBody3D.new()
    ground.name = "Ground"
    var mesh := PlaneMesh.new()
    mesh.size = Vector2(100, 100)
    var ground_mesh := MeshInstance3D.new()
    ground_mesh.mesh = mesh
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.25, 0.53, 0.26)
    mat.roughness = 1.0
    ground_mesh.material_override = mat
    ground.add_child(ground_mesh)
    var col := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(100, 0.2, 100)
    col.shape = shape
    col.position.y = -0.1
    ground.add_child(col)
    add_child(ground)

    # A few simple landmark props for depth and scale
    for i in range(12):
        var pillar := StaticBody3D.new()
        var pm := MeshInstance3D.new()
        var cylinder := CylinderMesh.new()
        cylinder.top_radius = 0.28
        cylinder.bottom_radius = 0.38
        cylinder.height = 1.7
        pm.mesh = cylinder
        var pmat := StandardMaterial3D.new()
        pmat.albedo_color = Color(0.58, 0.59, 0.62)
        pm.material_override = pmat
        pillar.add_child(pm)
        var pcol := CollisionShape3D.new()
        var pshape := CylinderShape3D.new()
        pshape.height = 1.7
        pshape.radius = 0.38
        pcol.shape = pshape
        pillar.add_child(pcol)
        pillar.position = Vector3((i % 4) * 7 - 10, 0.85, -12 - int(i / 4) * 6)
        add_child(pillar)

func build_player():
    player = CharacterBody3D.new()
    player.name = "Player"
    player.position = Vector3(0, 0.12, 0)
    var collider := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.38
    capsule.height = 1.75
    collider.shape = capsule
    collider.position.y = 0.88
    player.add_child(collider)

    # Character assembled from clean, colorful primitive meshes
    add_part(player, "Torso", BoxMesh.new(), Vector3(0, 1.05, 0), Vector3(0.62, 0.72, 0.38), Color(0.13, 0.42, 0.92))
    add_part(player, "Head", SphereMesh.new(), Vector3(0, 1.78, 0), Vector3(0.48, 0.48, 0.45), Color(0.94, 0.73, 0.52))
    add_part(player, "LeftArm", BoxMesh.new(), Vector3(-0.43, 1.08, 0), Vector3(0.22, 0.64, 0.24), Color(0.13, 0.42, 0.92))
    add_part(player, "RightArm", BoxMesh.new(), Vector3(0.43, 1.08, 0), Vector3(0.22, 0.64, 0.24), Color(0.13, 0.42, 0.92))
    add_part(player, "LeftLeg", BoxMesh.new(), Vector3(-0.17, 0.42, 0), Vector3(0.25, 0.62, 0.28), Color(0.12, 0.15, 0.22))
    add_part(player, "RightLeg", BoxMesh.new(), Vector3(0.17, 0.42, 0), Vector3(0.25, 0.62, 0.28), Color(0.12, 0.15, 0.22))
    add_part(player, "EyeL", SphereMesh.new(), Vector3(-0.12, 1.82, -0.205), Vector3(0.07, 0.07, 0.04), Color(0.08, 0.08, 0.08))
    add_part(player, "EyeR", SphereMesh.new(), Vector3(0.12, 1.82, -0.205), Vector3(0.07, 0.07, 0.04), Color(0.08, 0.08, 0.08))
    add_child(player)

    camera = Camera3D.new()
    camera.name = "FollowCamera"
    camera.current = true
    camera.fov = 70
    add_child(camera)
    camera.position = Vector3(0, 4.3, 7.5)
    camera.look_at(player.position + Vector3(0, 1.0, 0), Vector3.UP)

func add_part(parent: Node3D, part_name: String, mesh_resource: Mesh, pos: Vector3, scale_v: Vector3, color: Color):
    var mi := MeshInstance3D.new()
    mi.name = part_name
    mi.mesh = mesh_resource
    mi.position = pos
    mi.scale = scale_v
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.72
    mi.material_override = material
    parent.add_child(mi)

func build_ui():
    var canvas := CanvasLayer.new()
    canvas.name = "TouchUI"
    add_child(canvas)
    var title := Label.new()
    title.text = "3dBash"
    title.position = Vector2(24, 18)
    title.add_theme_font_size_override("font_size", 34)
    title.add_theme_color_override("font_color", Color(1, 1, 1))
    canvas.add_child(title)

    status_label = Label.new()
    status_label.text = "Mueve el joystick para caminar"
    status_label.position = Vector2(24, 64)
    status_label.add_theme_font_size_override("font_size", 18)
    status_label.add_theme_color_override("font_color", Color(1, 1, 1))
    canvas.add_child(status_label)

    joystick_base = Control.new()
    joystick_base.position = Vector2(60, -210)
    joystick_base.anchor_left = 0
    joystick_base.anchor_top = 1
    joystick_base.anchor_right = 0
    joystick_base.anchor_bottom = 1
    joystick_base.size = Vector2(180, 180)
    joystick_base.mouse_filter = Control.MOUSE_FILTER_STOP
    canvas.add_child(joystick_base)
    var base_draw := JoystickVisual.new()
    base_draw.is_knob = false
    base_draw.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    joystick_base.add_child(base_draw)
    joystick_knob = Control.new()
    joystick_knob.size = Vector2(74, 74)
    joystick_knob.position = Vector2(53, 53)
    var knob_draw := JoystickVisual.new()
    knob_draw.is_knob = true
    knob_draw.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    joystick_knob.add_child(knob_draw)
    joystick_base.add_child(joystick_knob)

    var hint := Label.new()
    hint.text = "JOYSTICK"
    hint.position = Vector2(90, -22)
    hint.anchor_top = 1
    hint.anchor_bottom = 1
    hint.add_theme_font_size_override("font_size", 13)
    hint.add_theme_color_override("font_color", Color(0.9, 0.95, 1, 0.7))
    canvas.add_child(hint)

func _process(delta):
    if player == null:
        return
    var input_vec := joystick_vector
    var forward := Vector3(0, 0, -1)
    var right := Vector3(1, 0, 0)
    var move_dir := right * input_vec.x + forward * input_vec.y
    if move_dir.length() > 0.08:
        move_dir = move_dir.normalized()
        player.velocity.x = move_dir.x * PLAYER_SPEED
        player.velocity.z = move_dir.z * PLAYER_SPEED
        player.rotation.y = atan2(move_dir.x, move_dir.z)
        status_label.text = "Caminando..."
    else:
        player.velocity.x = move_toward(player.velocity.x, 0, PLAYER_SPEED * 7 * delta)
        player.velocity.z = move_toward(player.velocity.z, 0, PLAYER_SPEED * 7 * delta)
        status_label.text = "Mueve el joystick para caminar"
    player.velocity.y -= 18.0 * delta
    player.move_and_slide()
    var target := player.global_position + Vector3(0, 1.0, 0)
    var desired_camera := player.global_position + Vector3(0, 4.0, 7.2)
    camera.global_position = camera.global_position.lerp(desired_camera, 5.0 * delta)
    camera.look_at(target, Vector3.UP)

func _input(event):
    if event is InputEventScreenTouch:
        if event.pressed and event.position.x < get_viewport().size.x * 0.48 and event.position.y > get_viewport().size.y * 0.48:
            joystick_active = true
            joystick_origin = joystick_base.global_position + joystick_base.size / 2
            update_joystick(event.position)
        elif not event.pressed:
            joystick_active = false
            joystick_vector = Vector2.ZERO
            joystick_knob.position = Vector2(53, 53)
    elif event is InputEventScreenDrag and joystick_active:
        update_joystick(event.position)
    elif event is InputEventMouseButton:
        if event.pressed and event.position.x < get_viewport().size.x * 0.48 and event.position.y > get_viewport().size.y * 0.48:
            joystick_active = true
            joystick_origin = joystick_base.global_position + joystick_base.size / 2
            update_joystick(event.position)
        elif not event.pressed:
            joystick_active = false
            joystick_vector = Vector2.ZERO
            joystick_knob.position = Vector2(53, 53)
    elif event is InputEventMouseMotion and joystick_active:
        update_joystick(event.position)

func update_joystick(pos: Vector2):
    var diff := pos - joystick_origin
    if diff.length() > JOY_RADIUS:
        diff = diff.normalized() * JOY_RADIUS
    joystick_vector = Vector2(diff.x / JOY_RADIUS, diff.y / JOY_RADIUS)
    joystick_knob.position = Vector2(53, 53) + diff * 0.65

class JoystickVisual extends Control:
    var is_knob := false
    func _draw():
        if is_knob:
            draw_circle(size / 2, Color(0.85, 0.94, 1, 0.9))
            draw_circle(size / 2, Color(0.18, 0.36, 0.52, 0.45), 3.0)
        else:
            draw_circle(size / 2, Color(0.1, 0.17, 0.25, 0.42))
            draw_arc(size / 2, 80, 0, TAU, 64, Color(0.75, 0.88, 1, 0.65), 4.0)
