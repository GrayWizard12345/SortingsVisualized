extends Control


var n_node
var algo_node
var algo_popup
var drawing_area
var left_top_corner
var right_bottom_corner
var start_button
var stream_palyer
var delay
var min_n = 10
var n = min_n
var x0 
var y0
var x1
var y1
var width
var height
var offset = 3
var rng = RandomNumberGenerator.new()
# Called when the node enters the scene tree for the first time.
var timer = 1

var pause = false
var mutex
var semaphore
#var pause_sem
var thread
func _ready():
	n_node = get_node("N")
	algo_node = get_node("Algo")
	drawing_area = get_node("Panel")
	left_top_corner = get_node("DAPos_LT")
	right_bottom_corner = get_node("DAPos_RB")
	start_button = get_node("Start")
	stream_palyer = AudioStreamPlayer.new()
	self.add_child(stream_palyer)
	stream_palyer.stream = load("res://Pew_Pew-DKnight556-1379997159.wav")
	
	stream_palyer.play()
	
	algo_node.add_item("BubleSort")
	algo_node.add_item("MergeSort")
	algo_node.add_item("RadixSort")
	
	x0 = left_top_corner.global_position[0]
	y0 = left_top_corner.global_position[1]
	x1 = right_bottom_corner.global_position[0]
	y1 = right_bottom_corner.global_position[1]
	width  = x1 - x0
	height = y1 - y0
	rng = RandomNumberGenerator.new()
	
	mutex = Mutex.new()
	semaphore = Semaphore.new()
#	pause_sem = Semaphore.new()
	thread = Thread.new()
	
var n_global = 10
func _on_N_text_changed(new_text):
	
	n_global = int(new_text)
	n_node.set_text(str(n_global))
	n_node.set_cursor_position(n_global+1)


var sorted = true
var elements = []
var old_color
func _on_Start_pressed():
	
	if start_button.text == "Start":
		
		mutex.lock()
		n = max(n_global, min_n)
		n_node.set_text(str(n))
		n_node.set_cursor_position(n+1)
		mutex.unlock()
		
		var h = height * 0.90
		rng.randomize()
		if elements.empty() or sorted:
			elements.clear()
			for i in range(n):
				elements.append(rng.randi_range(0, h))
		
		sorted = false
		start_button.text = "Pause"
		update()
		
		mutex.lock()
		termination = true
		pause = false
		mutex.unlock()
		semaphore.post()
#		pause_sem.post()
		
		if thread.is_active():
			thread.wait_to_finish()
			
		termination = false
		thread = Thread.new()
		thread.start(self, "sort_thread")
		
	
	elif start_button.text == "Pause":
		mutex.lock()
		pause = true
		mutex.unlock()
		start_button.text = "Continue"
		semaphore.post()
	
	elif start_button.text == "Continue":
		mutex.lock()
		pause = false
		mutex.unlock()
		start_button.text = "Pause"
#		pause_sem.post()


var comp_i
var comp_j
func _draw():
	if not sorted and not elements.empty():
		var x = x0 + 50
		var y = y1
		
		var el_width = (width-100) / n
		x += el_width / 2
		
		for i in range(n):
			var start = Vector2(x + i * el_width, y)
			var end = Vector2(x + i * el_width, y - elements[i])
			var color = Color(166,166,166)
			mutex.lock()
			if i == comp_i:
				color = Color(255,0,0, 0.5)
			if i == comp_j:
				color = Color(255,255,0, 0.5)
			mutex.unlock()
			draw_line(start, end, color, el_width)
	
		#var t = timer / 1000
		#yield(get_tree().create_timer(0.035), "timeout")
	semaphore.post()
			

var algo_names = ["BubleSort", "MergerSort", "RadixSort"]
var sorting_algo = algos.buble	#default
enum algos{
	buble, merge, radix
}
var thread_counter = 0
func sort_thread(userdata):
	# Sort one element and wait
	mutex.lock()
	thread_counter += 1
	mutex.unlock()
	print(thread_counter, " is running...")
	var local_n
	mutex.lock()
	local_n = n
	mutex.unlock()
	if not sorted:
		if sorting_algo == algos.buble:
			for i in range(local_n):
				mutex.lock()
				comp_i = i
				mutex.unlock()
				for j in range(i+1, local_n):
					mutex.lock()
					comp_j = j
					mutex.unlock()
					if elements[i] > elements[j]:
						var temp = elements[i]
						elements[i] = elements[j]
						elements[j] = temp
					update()
					semaphore.wait()
					
					if check_termination():
						return
					
		elif sorting_algo == algos.merge:
			if mergeSort(0, local_n-1) == -1:
				sorted = false
				print(thread_counter, " is stoped by main thread")
				thread_counter -= 1
				return
		elif sorting_algo == algos.radix:
			if radix_sort() == -1:
				sorted = false
				thread_counter -= 1
				return
				
				
				
		sorted = true
		start_button.text = "Start"
		print(thread_counter, " is finished")
		thread_counter -= 1
		



		
		
var termination = false
func _exit_tree():
	mutex.lock()
	termination = true
	mutex.unlock()
	semaphore.post()

	if thread.is_active():
		thread.wait_to_finish()
	
	


func _on_New_data_pressed():
	
	start_button.text = "Start"
	mutex.lock()
	termination = true
	mutex.unlock()
	semaphore.post()
	
	if thread.is_active():
		thread.wait_to_finish()
	
	var h = height * 0.90
	rng.randomize()
	elements.clear()
	n = n_global
	for i in range(n):
		elements.append(rng.randi_range(0, h))
	sorted = false
	comp_i = 0
	comp_j = 1
	update()

# algorithm choice event handler
func _on_Algo_item_selected(id):
	sorting_algo = id


# Python program in-place Merge Sort 

# Merges two subarrays of arr. 
# First subarray is arr[l..m] 
# Second subarray is arr[m+1..r] 
# Inplace Implementation 
func merge(start, mid, end): 
	var start2 = mid + 1; 
	
	# If the direct merge is already sorted 
	if (elements[mid] <= elements[start2]): 
		return; 
	
	# Two pointers to maintain start 
	# of both arrays to merge 
	while (start <= mid and start2 <= end):
		mutex.lock()
		comp_i = start
		comp_j = start2
		mutex.unlock() 
		update()
		semaphore.wait()
		
		if check_termination():
			return -1
		
		# If element 1 is in right place 
		if (elements[start] <= elements[start2]): 
			start += 1; 
		else: 
			var value = elements[start2]; 
			var index = start2; 

			# Shift all the elements between element 1 
			# element 2, right by 1. 
			while (index != start): 
				elements[index] = elements[index - 1]; 
				index -= 1; 
				
				mutex.lock()
				comp_i = start
				comp_j = start2+1
				mutex.unlock() 
				update()
				semaphore.wait()
				
				if check_termination():
					return -1
				
			elements[start] = value; 

			# Update all the pointers 
			start += 1; 
			mid += 1; 
			start2 += 1; 
		
#
#* l is for left index and r is right index of 
#the sub-array of arr to be sorted 
#
func mergeSort(l, r): 
	if (l < r): 

		# Same as (l + r) / 2, but avoids overflow 
		# for large l and r 
		var m = l + (r - l) / 2; 

		# Sort first and second halves
		var terminator = 0
		terminator = mergeSort(l, m);
		if terminator == -1:
			return -1
		terminator = mergeSort(m + 1, r); 
		if terminator == -1:
			return -1

		if merge(l, m, r) == -1:
			 return -1
	
func check_termination():
	mutex.lock()
	var shuld_exit = termination
	mutex.unlock()
	if shuld_exit:
		print(thread_counter, " is stoped by main thread")
		thread_counter -= 1
		return true
		
	return false


func radix_sort():
	
	
	var cur_pos = 1
	var k = elements[0]
	for i in elements:
		if k < i:
			k = i
	while k > 0:
		var arr = elements
		var buckets = [[], [], [], [], [], [], [], [], [], []]
		for j in range(len(arr)):
			buckets[(arr[j] / cur_pos) % 10].append(arr[j])
			mutex.lock()
			comp_i = j
			mutex.unlock()
			
			var x = 0
			var y = 0
			var i = 0
			while i <= j and x < len(buckets[y]):
				elements[i] = buckets[y][x]
				x += 1
				if x >= len(buckets[y]):
					y += 1
					x = 0
				i += 1
			
			update()
			semaphore.wait()
			
			if check_termination():
				return -1
					
		
			
		var mem = [] 
		for buck in buckets:
			for el in buck:
				mem.append(el)
		elements = mem
		
		cur_pos *= 10
		k /= 10
	

	
