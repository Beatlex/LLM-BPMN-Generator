extends RefCounted
class_name BpmnJsonValidator

static func validate(json: Array) -> Dictionary:
	var errors: Array = []

	if json.is_empty():
		errors.append("JSON ist leer.")
		return {"valid": false, "errors": errors}

	var ids := {}
	var start_events := 0
	var end_events := 0

	for element in json:
		if not element.has("element_id"):
			errors.append("Element ohne element_id gefunden.")
			continue

		var id = element.element_id
		if ids.has(id):
			errors.append("Doppelte element_id: %s" % id)
		ids[id] = true

		if not element.has("element_type"):
			errors.append("Element %s ohne element_type." % id)
			continue

		match element.element_type:
			"start_event":
				start_events += 1
			"end_event":
				end_events += 1
			"task", "exclusive_gateway", "parallel_gateway":
				if not element.has("flows_to") or element.flows_to.is_empty():
					errors.append("Element %s (%s) hat kein flows_to." %
						[id, element.element_type])

				if element.element_type.ends_with("gateway") and element.flows_to.size() < 2:
					errors.append("Gateway %s hat weniger als zwei ausgehende Flüsse." % id)
			_:
				errors.append("Unbekannter element_type bei %s." % id)

	# Referenzen prüfen
	for element in json:
		if element.has("flows_to"):
			for target in element.flows_to:
				if not ids.has(target):
					errors.append("flows_to verweist auf nicht existierende ID %s." % target)

	if start_events != 1:
		errors.append("Es muss genau ein Start-Event existieren.")

	if end_events < 1:
		errors.append("Mindestens ein End-Event erforderlich.")

	return {
		"valid": errors.is_empty(),
		"errors": errors
	}
