# json_to_bpmn.py
# Converts your JSON (schema v1.1) into BPMN 2.0 XML.
# Beginner-friendly: lots of comments. Runs with Python 3.10+.

import json
import sys
from xml.etree.ElementTree import Element, SubElement, tostring
import xml.dom.minidom as minidom

# -------- Helpers --------
def pretty(xml_bytes: bytes) -> str:
    """Return pretty-printed XML string."""
    return minidom.parseString(xml_bytes).toprettyxml(indent="  ")

def new_id(prefix: str, counter: dict) -> str:
    counter[prefix] = counter.get(prefix, 0) + 1
    return f"{prefix}_{counter[prefix]}"

# -------- Core conversion --------
def json_to_bpmn(data: dict) -> str:
    """
    Convert JSON schema v1.1 into BPMN XML.
    Supported:
      - Events: start, end, intermediate
      - Activities: userTask/serviceTask/receiveTask/... (+ loop)
      - Gateways: exclusive/parallel/inclusive
      - Sequence flows with optional condition
      - Swimlanes via 'lane' on nodes
    """
    # Root <definitions>
    defs = Element("definitions", {
        "xmlns": "http://www.omg.org/spec/BPMN/20100524/MODEL",
        "xmlns:bpmndi": "http://www.omg.org/spec/BPMN/20100524/DI",
        "xmlns:omgdc": "http://www.omg.org/spec/DD/20100524/DC",
        "xmlns:omgdi": "http://www.omg.org/spec/DD/20100524/DI",
        "id": "Definitions_1",
        "targetNamespace": "http://bpmn.io/schema/bpmn"
    })

    process_id = "Process_1"
    process = SubElement(defs, "process", {
        "id": process_id,
        "name": data.get("process_name", "Generated Process"),
        "isExecutable": "false"
    })

    # Laneset preparation (collect lanes used by nodes)
    lanes_used = set()
    for col in ("events", "activities", "gateways"):
        for item in data.get(col, []):
            lane = item.get("lane")
            if lane:
                lanes_used.add(lane)

    lane_id_by_name = {}
    lane_flowrefs = {ln: [] for ln in lanes_used}

    if lanes_used:
        lane_set = SubElement(process, "laneSet", {"id": "LaneSet_1"})
        for ln in sorted(lanes_used):
            lid = f"Lane_{ln.replace(' ', '_')}"
            lane_id_by_name[ln] = lid
            SubElement(lane_set, "lane", {"id": lid, "name": ln})

    # Maps node name -> BPMN id
    idmap: dict[str, str] = {}
    counter = {}

    # --- Events ---
    for ev in data.get("events", []):
        name = ev["name"]
        etype = ev.get("type", "intermediate").lower()
        if etype == "start":
            tag = "startEvent"
            eid = new_id("StartEvent", counter)
        elif etype == "end":
            tag = "endEvent"
            eid = new_id("EndEvent", counter)
        else:
            tag = "intermediateCatchEvent"
            eid = new_id("IntermediateEvent", counter)

        el = SubElement(process, tag, {"id": eid, "name": name})
        idmap[name] = eid

        # lane assignment
        ln = ev.get("lane")
        if ln in lane_flowrefs:
            lane_flowrefs[ln].append(eid)

    # --- Activities ---
    for act in data.get("activities", []):
        name = act["name"]
        task_type = act.get("taskType", "task")  # userTask, serviceTask, receiveTask, task...
        tag = task_type if task_type in {"userTask", "serviceTask", "receiveTask", "scriptTask", "sendTask"} else "task"
        tid = new_id("Activity", counter)
        task_el = SubElement(process, tag, {"id": tid, "name": name})
        idmap[name] = tid

        # optional loop marker
        if act.get("loop"):
            SubElement(task_el, "standardLoopCharacteristics")

        # lane assignment
        ln = act.get("lane")
        if ln in lane_flowrefs:
            lane_flowrefs[ln].append(tid)

    # --- Gateways ---
    gw_type_map = {
        "exclusive": "exclusiveGateway",
        "parallel": "parallelGateway",
        "inclusive": "inclusiveGateway"
    }
    for gw in data.get("gateways", []):
        name = gw["name"]
        gtype = gw.get("type", "exclusive").lower()
        tag = gw_type_map.get(gtype, "exclusiveGateway")
        gid = new_id("Gateway", counter)
        SubElement(process, tag, {"id": gid, "name": name})
        idmap[name] = gid

        ln = gw.get("lane")
        if ln in lane_flowrefs:
            lane_flowrefs[ln].append(gid)

    # --- Sequence Flows ---
    for flow in data.get("sequence", []):
        src = idmap.get(flow["from"])
        tgt = idmap.get(flow["to"])
        if not src or not tgt:
            # ignore unknown references to keep beginner friendly
            continue

        sf_id = new_id("Flow", counter)
        sf = SubElement(process, "sequenceFlow", {
            "id": sf_id, "sourceRef": src, "targetRef": tgt
        })

        # Conditional flows (used typically after gateways)
        cond = flow.get("condition")
        if cond:
            cond_el = SubElement(sf, "conditionExpression", {
                "xsi:type": "tFormalExpression"
            })
            # add xsi namespace only when first used
            defs.set("xmlns:xsi", "http://www.w3.org/2001/XMLSchema-instance")
            cond_el.text = cond

        # Optional default flow on gateway (extend schema later if desired)
        # if flow.get("default", False):
        #     # find element src and set default attribute
        #     # (left out for simplicity)

    # --- finalize lanes: add flowNodeRef entries
    if lanes_used:
        # Find the laneSet back and its lanes to append flowNodeRef
        # (ElementTree search is simple because we created them above)
        for lane_el in process.findall("laneSet/lane", namespaces={}):
            ln_name = lane_el.get("name")
            for ref in lane_flowrefs.get(ln_name, []):
                SubElement(lane_el, "flowNodeRef").text = ref

    # We do not generate BPMN-DI (diagram coordinates) – Camunda Modeler/bpmn.io
    # kann auto-layout. Später einfach ergänzbar.

    return pretty(tostring(defs))


def main():
    in_file = "input.json"
    out_file = "process.bpmn"
    if len(sys.argv) >= 2:
        in_file = sys.argv[1]
    if len(sys.argv) >= 3:
        out_file = sys.argv[2]

    with open(in_file, "r", encoding="utf-8") as f:
        data = json.load(f)

    xml = json_to_bpmn(data)

    with open(out_file, "w", encoding="utf-8") as f:
        f.write(xml)

    print(f"✅ BPMN-Datei erzeugt: {out_file}")


if __name__ == "__main__":
    main()
