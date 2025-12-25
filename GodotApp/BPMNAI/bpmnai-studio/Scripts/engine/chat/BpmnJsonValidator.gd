extends RefCounted
class_name BpmnJsonValidator

static func validate(json: Array) -> Dictionary:
	var errors: Array = []

	if json.is_empty():
		errors.append("JSON ist leer.")
		return {"valid": false, "errors": errors}

	var ids := {}
	var id_list: Array = []
	var incoming_count := {}
	var start_events := 0
	var end_events := 0

	# ---------- Init Incoming Map ----------
	for element in json:
		if element.has("element_id"):
			incoming_count[str(element.element_id)] = 0

	# ---------- Erste Runde: Struktur & Typen ----------
	for element in json:
		if not element.has("element_id"):
			errors.append("Element ohne element_id gefunden.")
			continue

		var id := str(element.element_id)

		if ids.has(id):
			errors.append("Doppelte element_id: %s" % id)
		ids[id] = true
		id_list.append(id)

		if not element.has("element_type"):
			errors.append("Element %s ohne element_type." % id)
			continue

		match element.element_type:
			"start_event":
				start_events += 1
				if not element.has("flows_to") or element.flows_to.is_empty():
					errors.append("Start-Event %s hat keinen ausgehenden Fluss." % id)

			"end_event":
				end_events += 1
				if element.has("flows_to") and not element.flows_to.is_empty():
					errors.append("End-Event %s darf keine ausgehenden Flüsse haben." % id)

			"task", "exclusive_gateway", "parallel_gateway", "inclusive_gateway":
				if not element.has("flows_to") or element.flows_to.is_empty():
					errors.append("Element %s (%s) hat kein flows_to." %
						[id, element.element_type])

			_:
				errors.append("Unbekannter element_type bei %s." % id)

	# ---------- Referenzen & Incoming zählen ----------
	for element in json:
		if element.has("flows_to"):
			for target in element.flows_to:
				var tid := str(target)
				if not ids.has(tid):
					errors.append("flows_to verweist auf nicht existierende ID %s." % tid)
				else:
					incoming_count[tid] += 1

	# ---------- Gateway-Semantik ----------
	for element in json:
		if not element.has("element_id") or not element.has("element_type"):
			continue

		var id := str(element.element_id)
		var in_count = incoming_count.get(id, 0)
		var out_count = element.flows_to.size() if element.has("flows_to") else 0

		match element.element_type:
			"parallel_gateway":
				# AND-Split
				if out_count >= 2 and in_count == 0:
					pass

				# AND-Join
				elif in_count >= 2 and out_count == 1:
					pass

				# AND-Split + Join kombiniert
				elif in_count >= 2 and out_count >= 2:
					pass

				else:
					errors.append(
						"Parallel-Gateway %s ist weder gültiger AND-Split noch AND-Join." % id
					)

			"exclusive_gateway":
				# XOR / OR brauchen keine Split/Join-Zwangslogik
				pass


	# ---------- Start / End Regeln ----------
	if start_events != 1:
		errors.append("Es muss genau ein Start-Event existieren.")

	if end_events < 1:
		errors.append("Mindestens ein End-Event erforderlich.")

	# ---------- Fortlaufende IDs prüfen ----------
	id_list.sort()
	for i in range(id_list.size()):
		if id_list[i] != str(i):
			errors.append("IDs sind nicht strikt fortlaufend ab 0.")

	return {
		"valid": errors.is_empty(),
		"errors": errors
	}
