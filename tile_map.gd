# TILE_MAP.GD
extends TileMap

signal end_game_lose
signal end_game_win

var chording_enabled : bool = true
var animation_enabled : bool = false

# Grid variables
var ROWS : int = 24
var COLS : int = 16
const CELL_SIZE : int = 85

# Tilemap variables
var mine_count : int
var tile_id : int = 0  # Set to 1 for color, or use below
var color_tile_id : int = 1
var cover_color : Color = '#ef801c'
var background_terrain = 0  # 0 for default background, 1 for light

# Layer variables
var mine_layer : int = 0
var number_layer : int = 1
var colored_number_layer : int = 7
var cover_layer : int = 2
var flag_layer : int = 3
var hover_layer : int = 4
var background_layer : int = 5

var dissolve_layer : int = 6
var flags_left = 0

# Atlast coordinates
var mine_atlas := Vector2i(1, 1)
var hover_atlas := Vector2i(2, 1)
var flag_atlas := Vector2i(0, 1)  # deprecate soon
var number_atlas : Array = generate_number_atlas(0)
var number_atlas2 : Array = generate_number_atlas(1)
var number_atlas3 : Array = generate_number_atlas(2)
var number_atlas4 : Array = generate_number_atlas(3)

# Array of mines positions
var mine_coords := []


func generate_number_atlas(x):
	var a := []
	for i in range(8):
		a.append(Vector2i(i, x))
	return a


# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Reset game
func new_game():
	mine_count = get_parent().TOTAL_MINES
	ROWS = get_parent().ROWS
	COLS = get_parent().COLS
	
	chording_enabled = get_parent().chording_enabled
	animation_enabled = get_parent().animation_enabled
	
	get_parent().first_click = true  # Reset first click flag
	
	if mine_count > (ROWS * COLS):
		print("More mines than cells")
		mine_count = ((ROWS * COLS) - 2)
	
	#if get_parent().colored_nums:
	#	tile_id = 1
	
	self.set_layer_z_index(0, 0)
	
	flags_left = mine_count
	
	clear()
	mine_coords.clear()
	
	generate_cover()
	generate_background()
	
	updateFlagLabel(get_parent().TOTAL_MINES)
	
	fade_cover = false
	fade_percent = 0
	var current_modulate = get_layer_modulate(cover_layer)
	current_modulate.a = 1
	set_layer_modulate(cover_layer, current_modulate)
	
	fade_cover_mine = false
	fade_percent_mine = 0


func check_top_row(num):
	num -= 1
	var max_columns = 4 if get_parent().difficulty == "easy" else 6
	for x in range(max_columns):
		var pos = Vector2(x, num)
		if (is_cover(pos) and !is_mine(pos)) or (is_flag(pos) and !is_mine(pos)):
			print("game over!")
			end_game_lose.emit()


# Generate mine positions
# control k to recomment below
func generate_mines(safe_zone: Array = []):
	mine_coords.clear()  # Clear existing mine coordinates
	for a in range(mine_count):
		var mine_pos = Vector2i(randi_range(0, COLS - 1), randi_range(0, ROWS - 1))
		while mine_coords.has(mine_pos) or mine_pos in safe_zone:
			mine_pos = Vector2i(randi_range(0, COLS - 1), randi_range(0, ROWS - 1))
		mine_coords.append(mine_pos)


		# Add mine to tilemap
		if get_parent().current_theme in ["Classic", "Classic Dark"]:
			set_cell(mine_layer, mine_pos, 4, Vector2i(9, 0))
		elif get_parent().current_theme in ["Classic Remastered", "Classic Remastered Dark"]:
			set_cell(mine_layer, mine_pos, 4, Vector2i(9, 2))
		elif get_parent().current_theme in ["Google", "Google Dark"]:
			set_cell(mine_layer, mine_pos, 4, Vector2i(11, 0))
		else:
			set_cell(mine_layer, mine_pos, tile_id, mine_atlas)





func regenerate_mines():
	#for every mine on the board, get its position as mine_pos, then:
	for mine_pos in mine_coords:
		if get_parent().current_theme in ["Classic", "Classic Dark"]:
			set_cell(mine_layer, mine_pos, 4, Vector2i(9, 0))
		elif get_parent().current_theme in ["Classic Remastered", "Classic Remastered Dark"]:
			set_cell(mine_layer, mine_pos, 4, Vector2i(9, 2))
		elif get_parent().current_theme in ["Google", "Google Dark"]:
			set_cell(mine_layer, mine_pos, 4, Vector2i(11, 0))
		else:
			set_cell(mine_layer, mine_pos, tile_id, mine_atlas)



#var color_tile_id : int = 1

var classic_number_layer : int = 8

# Generate numbers based off mines
func generate_numbers():
	clear_layer(number_layer)
	for i in get_empty_cells():
		var mine_count : int = 0
		for j in get_all_surrounding_cells(i):
			# Check if mine in cell
			if is_mine(j):
				mine_count += 1
		# Once counted, add number to tilemap
		if mine_count > 0:
			set_cell(number_layer, i, tile_id, number_atlas[mine_count-1])
	
	# colored
	clear_layer(colored_number_layer)
	for i in get_empty_cells():
		var mine_count : int = 0
		for j in get_all_surrounding_cells(i):
			# Check if mine in cell
			if is_mine(j):
				mine_count += 1
		# Once counted, add number to tilemap
		if mine_count > 0:
			set_cell(colored_number_layer, i, color_tile_id, number_atlas[mine_count-1])
	
	# classic
	clear_layer(classic_number_layer)
	if get_parent().current_theme in ["Classic", "Classic Dark", "Classic Remastered", "Classic Remastered Dark", "Google", "Google Dark"]:
		for i in get_empty_cells():
			var mine_count : int = 0
			for j in get_all_surrounding_cells(i):
				# Check if mine in cell
				if is_mine(j):
					mine_count += 1
			# Once counted, add number to tilemap
			if mine_count > 0:
				if get_parent().current_theme == "Classic":
					set_cell(classic_number_layer, i, 4, number_atlas[mine_count-1])
				elif get_parent().current_theme == "Classic Dark":
					set_cell(classic_number_layer, i, 4, number_atlas2[mine_count-1])
				elif get_parent().current_theme in ["Classic Remastered", "Google", "Google Dark"]:
					set_cell(classic_number_layer, i, 4, number_atlas3[mine_count-1])
				elif get_parent().current_theme == "Classic Remastered Dark":
					set_cell(classic_number_layer, i, 4, number_atlas4[mine_count-1])
	
	set_layer_z_index(number_layer, 0)
	set_layer_z_index(colored_number_layer, -10)
	set_layer_z_index(classic_number_layer, -10)
	if get_parent().colored_nums:
		set_layer_z_index(number_layer, -10)
		set_layer_z_index(classic_number_layer, -10)
		set_layer_z_index(colored_number_layer, 0)
	
	if get_parent().current_theme in ["Classic", "Classic Dark", "Classic Remastered", "Classic Remastered Dark", "Google", "Google Dark"]:
		set_layer_z_index(number_layer, -10)
		set_layer_z_index(colored_number_layer, -10)
		set_layer_z_index(classic_number_layer, 0)

func regenerate_numbers():
	var visible_number_positions = []
	for y in range(ROWS):
		for x in range(COLS):
			var pos = Vector2i(x, y)
			if is_number(pos):
				visible_number_positions.append(pos)
	
	if visible_number_positions.is_empty():
		return  # No visible numbers, so nothing to regenerate
	
	for pos in visible_number_positions:
		var mine_count = 0
		for neighbor in get_all_surrounding_cells(pos):
			if is_mine(neighbor):
				mine_count += 1
		
		if mine_count > 0:
			set_layer_z_index(classic_number_layer, 0)
			set_layer_z_index(number_layer, -10)
			set_layer_z_index(colored_number_layer, -10)
			
			if get_parent().current_theme == "Classic":
				set_cell(classic_number_layer, pos, 4, number_atlas[mine_count-1])
			elif get_parent().current_theme == "Classic Dark":
				set_cell(classic_number_layer, pos, 4, number_atlas2[mine_count-1])
			elif get_parent().current_theme in ["Classic Remastered", "Google", "Google Dark"]:
				set_cell(classic_number_layer, pos, 4, number_atlas3[mine_count-1])
			elif get_parent().current_theme == "Classic Remastered Dark":
				set_cell(classic_number_layer, pos, 4, number_atlas4[mine_count-1])
			else:
				set_layer_z_index(number_layer, 0)
				set_layer_z_index(colored_number_layer, -10)
				set_layer_z_index(classic_number_layer, -10)
				
				if get_parent().colored_nums:
					set_layer_z_index(number_layer, -10)
					set_layer_z_index(classic_number_layer, -10)
					set_layer_z_index(colored_number_layer, 0)
				
				set_cell(number_layer, pos, tile_id, number_atlas[mine_count-1])
				set_cell(colored_number_layer, pos, color_tile_id, number_atlas[mine_count-1])


func generate_cover():
	var positions := []
	# Collect all positions in the grid
	for y in range(ROWS):
		for x in range(COLS):
			positions.append(Vector2i(x, y))
	
	if get_parent().current_theme == "Classic":
		set_cells_terrain_connect(cover_layer, positions, 2,  0)
	elif get_parent().current_theme == "Classic Dark":
		set_cells_terrain_connect(cover_layer, positions, 2,  1)
	elif get_parent().current_theme == "Classic Remastered":
		set_cells_terrain_connect(cover_layer, positions, 2,  2)
	elif get_parent().current_theme == "Classic Remastered Dark":
		set_cells_terrain_connect(cover_layer, positions, 2,  3)
	elif get_parent().current_theme == "Google":
		for y in range(ROWS):
			for x in range(COLS):
				var toggle = ((x + y) % 2)
				set_cell(cover_layer, Vector2i(x, y), 4, Vector2i(9 - toggle, 4))  # 8,4  and  9,4
	elif get_parent().current_theme == "Google Dark":
		for y in range(ROWS):
			for x in range(COLS):
				var toggle = ((x + y) % 2)
				set_cell(cover_layer, Vector2i(x, y), 4, Vector2i(9 - toggle, 5))  # 8,4  and  9,4
	else:
		set_cells_terrain_connect(cover_layer, positions, 0,  0)


func regenerate_cover():
	var covered_positions = []
	for y in range(ROWS):
		for x in range(COLS):
			var pos = Vector2i(x, y)
			if is_cover(pos):
				covered_positions.append(pos)
	
	if covered_positions.is_empty():
		return  # No covered positions, so nothing to regenerate
	else:
		if get_parent().current_theme == "Classic":
			set_cells_terrain_connect(cover_layer, covered_positions, 2,  0)
		elif get_parent().current_theme == "Classic Dark":
			set_cells_terrain_connect(cover_layer, covered_positions, 2,  1)
		elif get_parent().current_theme == "Classic Remastered":
			set_cells_terrain_connect(cover_layer, covered_positions, 2,  2)
		elif get_parent().current_theme == "Classic Remastered Dark":
			set_cells_terrain_connect(cover_layer, covered_positions, 2,  3)
		elif get_parent().current_theme == "Google":
			for thispos in covered_positions:
				var toggle = ((thispos[0] + thispos[1]) % 2)
				set_cell(cover_layer, thispos, 4, Vector2i(9 - toggle, 4))
		elif get_parent().current_theme == "Google Dark":
			for thispos in covered_positions:
				var toggle = ((thispos[0] + thispos[1]) % 2)
				set_cell(cover_layer, thispos, 4, Vector2i(9 - toggle, 5))
		else:
			set_cells_terrain_connect(cover_layer, covered_positions, 0,  0)


func regenerate_flags():
	var flagged_positions = []
	for y in range(ROWS):
		for x in range(COLS):
			var pos = Vector2i(x, y)
			if is_flag(pos):
				flagged_positions.append(pos)
	
	if flagged_positions.is_empty():
		return  # No flagged positions, so nothing to regenerate
	else:
		if get_parent().current_theme == "Classic":
			set_cells_terrain_connect(flag_layer, flagged_positions, 3, 0)
		elif get_parent().current_theme == "Classic Dark":
			set_cells_terrain_connect(flag_layer, flagged_positions, 3, 1)
		elif get_parent().current_theme == "Classic Remastered":
			set_cells_terrain_connect(flag_layer, flagged_positions, 3, 2)
		elif get_parent().current_theme == "Classic Remastered Dark":
			set_cells_terrain_connect(flag_layer, flagged_positions, 3, 3)
		elif get_parent().current_theme == "Google":
			for thispos in flagged_positions:
				var toggle = ((thispos.x + thispos.y) % 2)
				set_cell(flag_layer, thispos, 4, Vector2i(11 - toggle, 3))
		elif get_parent().current_theme == "Google Dark":
			for thispos in flagged_positions:
				var toggle = ((thispos.x + thispos.y) % 2)
				set_cell(flag_layer, thispos, 4, Vector2i(11 - toggle, 5))
		else:
			set_cells_terrain_connect(flag_layer, flagged_positions, 0, 1)


func generate_background():
	var positions := []
	# Collect all positions in the grid
	
	if get_parent().current_theme in ["Google", "Google Dark"]:
		for y in range(ROWS):
			for x in range(COLS):
				var toggle = ((x + y) % 2)
				set_cell(background_layer, Vector2i(x, y), 4, Vector2i(11 - toggle, 4))  # 8,4  and  9,4
	else:
		for y in range(ROWS):
			for x in range(COLS):
				positions.append(Vector2i(x, y))
		
		if get_parent().current_theme in ["Classic", "Classic Remastered"]:
			set_cells_terrain_connect(background_layer, positions, 1, 2)
		elif get_parent().current_theme in ["Classic Dark", "Classic Remastered Dark"]:
			set_cells_terrain_connect(background_layer, positions, 1, 3)
		else:
			set_cells_terrain_connect(background_layer, positions, 1, background_terrain)


func get_empty_cells():
	var empty_cells := []
	for y in range(ROWS):
		for x in range(COLS):
			if not is_mine(Vector2i(x, y)):
				empty_cells.append(Vector2i(x, y))
	return empty_cells

# Calculate surrounding cells given middle
func get_all_surrounding_cells(middle_cell):
	var surrounding_cells := []
	var target_cell
	for y in range(3):
		for x in range(3):
			target_cell = middle_cell + Vector2i(x-1, y-1)
			# Skip middle cell
			if target_cell != middle_cell:
				# Check if cell on grid
				if (target_cell.x >= 0 and target_cell.x <= COLS-1
					and target_cell.y >= 0 and target_cell.y <= ROWS-1):
						surrounding_cells.append(target_cell)
	return surrounding_cells


func _unhandled_input(event):  # _input(event) -> _unhandled_input(event) fixed clicking thru ui
	if event is InputEventMouseButton and event.pressed and !get_parent().freezeGame:
	#if (Input.is_action_just_pressed("L_CLICK") or Input.is_action_just_pressed("R_CLICK")) and !get_parent().freezeGame:
		
		var zoom = $"../GameCamera".zoom
		var camera_offset = get_parent().camera_offset
		#var corrected_pos = (event.position + camera_offset) / zoom
		var grid_pos = local_to_map(event.position)
		
		var corrected_pos : Vector2 = get_local_mouse_position()
		
		var in_bounds = false
		if (local_to_map(corrected_pos).x >= 0 and local_to_map(corrected_pos).x < COLS) and (local_to_map(corrected_pos).y >= 0 and local_to_map(corrected_pos).y < ROWS):
			in_bounds = true
		
		
		# Check mouse is on gameboard
		#if event.position.y < ROWS * CELL_SIZE:
		if in_bounds:
			var map_pos := local_to_map(corrected_pos)
			
			if get_parent().flag_mode or get_parent().holding_flag:
				if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
					if is_number(map_pos) and not is_cover(map_pos):
						if chording_enabled:
							scan_mines(map_pos)
					
					process_right_click(map_pos)  # Left click acts like a right click
				elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
					if not is_flag(map_pos):
						if is_mine(map_pos):
							if get_parent().first_click:
								move_mine(map_pos)
								generate_numbers()
								process_left_click(map_pos)
							else:
								bomb_det()
						else:
							process_left_click(map_pos)  # Right click acts like a left click
			else:
				if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
					if is_number(map_pos) and not is_cover(map_pos):
						if chording_enabled:
							scan_mines(map_pos)
					
					if not is_flag(map_pos):
						if is_mine(map_pos):
							if get_parent().first_click:
								move_mine(map_pos)
								generate_numbers()
								process_left_click(map_pos)
							else:
								bomb_det()
						else:
							process_left_click(map_pos)
				# Rightclick: flag
				elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
					process_right_click(map_pos)


func process_left_click(pos):
	if is_cover(pos):
		if get_parent().enable_sound:
			$"../SFX/Click".play()
	
	if get_parent().first_click:
		get_parent().first_click = false
		#print("First click at: ", pos)
		
		# Define a 3x3 safe zone around the first click
		var safe_zone = get_all_surrounding_cells(pos)
		safe_zone.append(pos)  # Include the clicked cell
		
		# Generate mines while avoiding the safe zone
		generate_mines(safe_zone)
		generate_numbers()
	
	
	# Reset pressure timer on click 
	if get_parent().GAMEMODE == "underpressure":
		if is_cover(pos):
			get_parent().countdown_time = 0
			get_parent().reset_countdown_anim()
			$"../SFX/Pressure".stop()
	
	
	# Proceed with revealing cells
	var revealed_cells := []
	var cells_to_reveal := [pos]
	var cells_to_reveal_real := []
	
	# if clearing on click doesn't work, del is_cover(pos) below
	while not cells_to_reveal.is_empty() and is_cover(pos):
		var current_cell = cells_to_reveal.pop_front()
	
		# Skip already revealed cells
		if revealed_cells.has(current_cell):
			continue
	
		# Mark the current cell as revealed
		revealed_cells.append(current_cell)
		cells_to_reveal_real.append(current_cell)
	
		# Remove flag if it exists
		if is_flag(current_cell):
			var tempPos := []
			tempPos.append(current_cell)
			set_cells_terrain_connect(flag_layer, tempPos, 0, -1, false)
			updateFlagLabel(mine_count - self.get_used_cells(flag_layer).size())
	
		# If the current cell is a number, stop expanding
		if is_number(current_cell):
			continue
	
		# Add surrounding cells for further revealing
		for neighbor in get_all_surrounding_cells(current_cell):
			if not revealed_cells.has(neighbor) and not cells_to_reveal.has(neighbor):
				cells_to_reveal.append(neighbor)
	
	
	# Update the cover layer for all revealed cells
	var cells_to_reveal_by_distance = sort_cells_by_distance(pos, cells_to_reveal_real)
	#print("Cells sorted by distance:")
	for i in range(cells_to_reveal_by_distance.size()):
		#print(i, " away: ", cells_to_reveal_by_distance[i])
		pass
	if animation_enabled:
		animate_cells(cells_to_reveal_real)
	
	
	# Remove cover layer over number & blank cells
	set_cells_terrain_connect(cover_layer, cells_to_reveal_real, 0, -1, false)
	
	
	# Check if all number tiles are cleared
	var all_cleared := true
	for cell in get_used_cells(number_layer):
		if is_cover(cell):
			all_cleared = false
	if all_cleared and flags_left >= 0:
		
		var surrounding_mines : int = 0
		var surrounding_flags : int = 0
		for cell in get_all_surrounding_cells(pos):
			if is_mine(cell):
				surrounding_mines += 1
			if is_flag(cell):
				surrounding_flags += 1
		
		if surrounding_mines >= surrounding_flags:
			end_game_win.emit()
			clear_layer(hover_layer)
			
			fade_cover = true
			updateFlagLabel(0)



func sort_cells_by_distance(center, cells):
	var cells_by_distance = {}
	for cell in cells:
		var distance = abs(cell.x - center.x) + abs(cell.y - center.y)
		if not cells_by_distance.has(distance):
			cells_by_distance[distance] = []
		cells_by_distance[distance].append(cell)
	
	# Convert the dictionary to a sorted array of arrays
	var sorted_cells = []
	var sorted_keys = cells_by_distance.keys()
	sorted_keys.sort()  # Sort the keys in place
	for key in sorted_keys:
		sorted_cells.append(cells_by_distance[key])
	return sorted_cells


func process_right_click(pos):
	var tempPos := []
	tempPos.append(pos)
	
	if is_cover(pos) or is_flag(pos):
		if get_parent().enable_sound:
			$"../SFX/Flag".play()
	
	if is_cover(pos):
		if not is_flag(pos):
			# place flag
			get_parent().noFlagsUsed = false
			
			if get_parent().current_theme == "Classic":
				set_cells_terrain_connect(flag_layer, tempPos, 3, 0, false)
			elif get_parent().current_theme == "Classic Dark":
				set_cells_terrain_connect(flag_layer, tempPos, 3, 1, false)
			elif get_parent().current_theme == "Classic Remastered":
				set_cells_terrain_connect(flag_layer, tempPos, 3, 2, false)
			elif get_parent().current_theme == "Classic Remastered Dark":
				set_cells_terrain_connect(flag_layer, tempPos, 3, 3, false)
				
			elif get_parent().current_theme == "Google":
				var toggle = ((tempPos[0][0] + tempPos[0][1]) % 2)
				set_cell(flag_layer, Vector2i(tempPos[0]), 4, Vector2i(11 - toggle, 3))
			elif get_parent().current_theme == "Google Dark":
				var toggle = ((tempPos[0][0] + tempPos[0][1]) % 2)
				set_cell(flag_layer, Vector2i(tempPos[0]), 4, Vector2i(11 - toggle, 5))
				
			else:
				set_cells_terrain_connect(flag_layer, tempPos, 0, 1, false)
			
			# remove cover
			set_cells_terrain_connect(cover_layer, tempPos, 0, -1, false)
			
			updateFlagLabel(mine_count - self.get_used_cells(flag_layer).size())
	elif is_flag(pos):
		# erase flag
		set_cells_terrain_connect(flag_layer, tempPos, 0, -1, false)
		
		# replace cover
		if get_parent().current_theme == "Classic":
			set_cells_terrain_connect(cover_layer, tempPos, 2,  0)
		elif get_parent().current_theme == "Classic Dark":
			set_cells_terrain_connect(cover_layer, tempPos, 2,  1)
		elif get_parent().current_theme == "Classic Remastered":
			set_cells_terrain_connect(cover_layer, tempPos, 2,  2)
		elif get_parent().current_theme == "Classic Remastered Dark":
			set_cells_terrain_connect(cover_layer, tempPos, 2,  3)
		elif get_parent().current_theme == "Google":
			var toggle = ((tempPos[0][0] + tempPos[0][1]) % 2)
			set_cell(cover_layer, Vector2i(tempPos[0]), 4, Vector2i(9 - toggle, 4))
		elif get_parent().current_theme == "Google Dark":
			var toggle = ((tempPos[0][0] + tempPos[0][1]) % 2)
			set_cell(cover_layer, Vector2i(tempPos[0]), 4, Vector2i(9 - toggle, 5))
		else:
			set_cells_terrain_connect(cover_layer, tempPos, 0, 0, false)
		
		updateFlagLabel(mine_count - self.get_used_cells(flag_layer).size())

func reveal_surrounding_cells(cells_to_reveal, revealed_cells):
	print("revealing surrounding cells")
	for i in get_all_surrounding_cells(cells_to_reveal[0]):
		if not revealed_cells.has(i):
			if not cells_to_reveal.has(i):
				cells_to_reveal.append(i)
	return cells_to_reveal


var fade_cover_mine = false
var fade_percent_mine = 0
func bomb_det():
	self.set_layer_z_index(0, 2)
	clear_layer(hover_layer)
	end_game_lose.emit()
	
	if get_parent().enable_sound:
		$"../SFX/Explode".play()
	
	# set bomb layer alpha to 0
	fade_cover_mine = true


func move_mine(old_pos):
	for y in range(ROWS):
		for x in range(COLS):
			if not is_mine(Vector2i(x, y)) and get_parent().first_click == true:
				#update arry
				mine_coords[mine_coords.find(old_pos)] = Vector2i(x, y)
				erase_cell(mine_layer, old_pos)
				set_cell(mine_layer, Vector2i(x, y), tile_id, mine_atlas)
				get_parent().first_click = false

func scan_mines(pos):
	var unflagged_mines : int = 0
	var surrounding_flags : int = 0
	var surrounding_mines : int = 0
	var surrounding_cells = get_all_surrounding_cells(pos)
	
	
	for cell in surrounding_cells:
		# Count incorrectly flagged cells
		if is_flag(cell):
			surrounding_flags += 1
		if is_mine(cell):
			surrounding_mines += 1
	
	
	for cell in surrounding_cells:
		# Count incorrectly flagged cells
		if is_flag(cell) and not is_mine(cell):
			if not is_flag(pos):
				if surrounding_flags == surrounding_mines:
					bomb_det()
		
		# Count unflagged mines
		if is_mine(cell) and not is_flag(cell):
			unflagged_mines += 1
	
	#print("surrounding_flags: " + str(surrounding_flags))
	#print("surrounding_mines: " + str(surrounding_mines))
	#print("unflagged mines = " + str(unflagged_mines))
	
	# If no unflagged mines, reveal surrounding non-mine cells
	if unflagged_mines == 0 and (surrounding_mines == surrounding_flags):
		for cell in surrounding_cells:
			if is_cover(cell) and not is_mine(cell):
				process_single_reveal(cell)
	else:
		if get_parent().enable_sound:
			$"../SFX/Deny".play()

# Helper function to reveal a single cell safely
func process_single_reveal(cell):
	if is_cover(cell) and not is_flag(cell):
		process_left_click(cell)


var fade_cover = false
var fade_percent = 0
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !get_parent().freezeGame:
		highlight_cell()
	
	if fade_cover and (fade_percent < 100):
		fade_percent += 1
		
		# Calculate the new alpha value based on fade_percent
		var new_alpha = 1.0 - (fade_percent / 100.0)
		
		# Get the current modulate color
		var current_modulate = get_layer_modulate(cover_layer)
		
		# Set the new modulate color with the adjusted alpha
		current_modulate.a = new_alpha
		set_layer_modulate(cover_layer, current_modulate)
	
	if fade_cover_mine and (fade_percent_mine < 100):
		fade_percent_mine += 3
		
		var new_alpha = (fade_percent_mine / 100.0)
		
		var current_modulate = get_layer_modulate(0)
		
		current_modulate.a = new_alpha
		set_layer_modulate(0, current_modulate)


func highlight_cell():
	var mouse_pos := local_to_map(get_local_mouse_position())
	# Clear hover tiles
	clear_layer(hover_layer)
	# Hover over cover cells
	if is_cover(mouse_pos):
		if get_parent().current_theme in ["Classic", "Classic Dark", "Classic Remastered", "Classic Remastered Dark", "Google", "Google Dark"]:
			set_cell(hover_layer, mouse_pos, 4, Vector2i(11,2))
		else:
			set_cell(hover_layer, mouse_pos, tile_id, hover_atlas)
	else:
		if is_number(mouse_pos):
			if get_parent().current_theme in ["Classic", "Classic Dark", "Classic Remastered", "Classic Remastered Dark", "Google", "Google Dark"]:
				set_cell(hover_layer, mouse_pos, 4, Vector2i(11,2))
			else:
				set_cell(hover_layer, mouse_pos, tile_id, hover_atlas)


func animate_cells(cells):
	print("animating cells...")
	for cell in cells:
		#set_cell(dissolve_layer, mouse_pos, tile_id, hover_atlas)
		#set_cell(dissolve_layer, cell, 2, Vector2i(0, 0))  # this cell should be set to atlas (9, 0) after 0.45s
		
		# wait 0.05s and then dissolve next cell
		#await get_tree().create_timer(0.45).timeout
		#set_cell(dissolve_layer, cell, 2, Vector2i(9, 0))
		
		pass


# Helper functions
func is_mine(pos):
	return get_cell_source_id(mine_layer, pos) != -1

func is_cover(pos):
	return get_cell_source_id(cover_layer, pos) != -1

func is_number(pos):
	return get_cell_source_id(number_layer, pos) != -1

func is_flag(pos):
	return get_cell_source_id(flag_layer, pos) != -1

func clear_cover_layer():
	clear_layer(cover_layer)

func updateFlagLabel(count):
	var spacer = "   "
	if str(count).length() >= 3:
		spacer = "   "
	elif str(count).length() >= 2:
		spacer = "   "
	get_parent().flagsLeft.text = spacer + str(count)
	flags_left = count
	
