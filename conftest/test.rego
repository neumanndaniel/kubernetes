package main

missingServiceAccount(obj, field) {
	not obj[field]
}

missingServiceAccount(obj, field) {
	obj[field] == ""
}

missing(obj) {
	not obj.automountServiceAccountToken == true
	not obj.automountServiceAccountToken == false
	missingServiceAccount(obj, "serviceAccount")
}

missing(obj) {
	not obj.automountServiceAccountToken == true
	not obj.automountServiceAccountToken == false
	obj.serviceAccount == "default"
}

check(obj) {
	obj.automountServiceAccountToken
	missingServiceAccount(obj, "serviceAccount")
}

check(obj) {
	obj.automountServiceAccountToken
	obj.serviceAccount == "default"
}

violation[{"msg": msg}] {
	p := input_pod[_]
	missing(p.spec)
	msg := sprintf("automountServiceAccountToken field is missing for %v %v while using Service Account default", [input.kind, input.metadata.name])
}

violation[{"msg": msg, "details": {}}] {
	p := input_pod[_]
	check(p.spec)
	msg := sprintf("Service Account token automount is not allowed for %v %v while using Service Account default, spec.automountServiceAccountToken: %v", [input.kind, input.metadata.name, p.spec.automountServiceAccountToken])
}

input_pod[p] {
	input.kind == "Deployment"
	p := input.spec.template
}

input_pod[p] {
	input.kind == "CronJob"
	p := input.spec.jobTemplate.spec.template
}

input_pod[p] {
	input.kind == "Pod"
	p := input
}
