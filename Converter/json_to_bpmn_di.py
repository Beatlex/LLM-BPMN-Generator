import json
import sys
from xml.etree.ElementTree import Element, SubElement, tostring
import xml.dom.minidom as minidom

def pretty(xml_bytes: bytes) -> str:
    return minidom.parseString(xml_bytes).toprettyxml(indent="  ")

def new_id(prefix: str, counter: dict) -> str:
    counter[prefix] = counter.get(prefix, 0) + 1
    return f"{prefix}_{counter[prefix]}"

def main():
    # -----------------------------
    # 1) LOAD JSON
    # -----------------------------
    in_file = sys.argv[1]
    out_file = sys.argv[2]

    with open(in_file, "r", encoding="utf-8") as f:
        data = json.load(f)

    print("\n========== DEBUG START ==========\n")
    print("JSON geladen.\n")

    # Debug: Show keys
    print("Top-Level Keys:", list(data.keys()))

    # Debug: Check elements structure
    if "elements" in data:
        print(f"✅ elements: {len(data['elements'])}")

        for el in data["elements"]:
            print(" - Element:", el.get("id"), "type:", el.get("type"))
    else:
        print("❌ JSON enthält KEIN 'elements'-Feld! Prozess wird leer sein!")

    # Debug flows
    flows = data.get("flows", {})
    print(f"\n✅ sequenceFlows: {len(flows.get('sequenceFlows', []))}")
    print(f"✅ messageFlows: {len(flows.get('messageFlows', []))}")
    print(f"✅ associations: {len(flows.get('associations', []))}")

    print("\n========== DEBUG END ==========\n")

    # -----------------------------
    # 2) CREATE MINIMAL BPMN
    # -----------------------------
    defs = Element("definitions", {
        "xmlns": "http://www.omg.org/spec/BPMN/20100524/MODEL",
        "xmlns:bpmndi": "http://www.omg.org/spec/BPMN/20100524/DI",
        "xmlns:omgdc": "http://www.omg.org/spec/DD/20100524/DC",
        "xmlns:omgdi": "http://www.omg.org/spec/DD/20100524/DI",
        "id": "Definitions_1",
        "targetNamespace": "http://bpmn.io/schema/bpmn"
    })

    process = SubElement(defs, "process", {
        "id": "Process_1",
        "name": data.get("metadata", {}).get("name", "Generated Process"),
        "isExecutable": "false"
    })

    # -----------------------------
    # 3) FIX: Convert ALL elements[]
    # -----------------------------
    idmap = {}
    counter = {}

    for el in data.get("elements", []):
        etype = el.get("type")
        eid = el.get("id", new_id("Node", counter))
        name = el.get("name", etype)

        if etype == "startEvent":
            tag = "startEvent"
        elif etype == "endEvent":
            tag = "endEvent"
        elif etype == "intermediateCatchEvent":
            tag = "intermediateCatchEvent"
        elif etype == "gateway":
            gw = el.get("gatewayType", "exclusive")
            tag = {
                "exclusive": "exclusiveGateway",
                "parallel": "parallelGateway",
                "inclusive": "inclusiveGateway"
            }.get(gw, "exclusiveGateway")
        elif etype == "task":
            task_type = el.get("taskType", "task")
            tag = {
                "standard": "task",
                "user": "userTask",
                "service": "serviceTask",
            }.get(task_type, "task")
        else:
            tag = "task"  # fallback

        # Create BPMN element
        node = SubElement(process, tag, {"id": eid, "name": name})
        idmap[eid] = eid

    # -----------------------------
    # 4) Convert flows
    # -----------------------------
    for f in data.get("flows", {}).get("sequenceFlows", []):
        SubElement(process, "sequenceFlow", {
            "id": f.get("id", new_id("Flow", counter)),
            "sourceRef": f["source"],
            "targetRef": f["target"]
        })

    xml = pretty(tostring(defs))

    with open(out_file, "w", encoding="utf-8") as f:
        f.write(xml)

    print(f"✅ BPMN-Datei erzeugt: {out_file}")


if __name__ == "__main__":
    main()
