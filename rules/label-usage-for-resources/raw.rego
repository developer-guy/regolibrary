package armo_builtins
# Deny mutating action unless user is in group owning the resource



deny[msga] {

	pod := input[_]
	pod.kind == "Pod"
	path := noLabelOrNoLabelUsage(pod, "")

    msga := {
		"alertMessage": sprintf("in the following pods a certain set of labels is not defined: %v", [pod.metadata.name]),
		"packagename": "armo_builtins",
		"alertScore": 2,
		"failedPaths": path,
         "alertObject": {
			"k8sApiObjects": [pod]
		}
     }
}


deny[msga] {
	wl := input[_]
	spec_template_spec_patterns := {"Deployment","ReplicaSet","DaemonSet","StatefulSet","Job"}
	spec_template_spec_patterns[wl.kind]
	podSpec := wl.spec.template
	begginingOfPodPath := "spec.template."
	path := noLabelUsage(wl, podSpec, begginingOfPodPath)

    msga := {
		"alertMessage": sprintf("%v: %v a certain set of labels is not defined:", [wl.kind, wl.metadata.name]),
		"packagename": "armo_builtins",
		"alertScore": 2,
		"failedPaths": path,
         "alertObject": {
			"k8sApiObjects": [wl]
		}
     }
}

#handles cronjob
deny[msga] {
	wl := input[_]
	wl.kind == "CronJob"
	podSpec := wl.spec.jobTemplate.spec.template
	begginingOfPodPath := "spec.jobTemplate.spec.template."
	path := noLabelUsage(wl, podSpec, begginingOfPodPath)


    msga := {
		"alertMessage": sprintf("the following cronjobs a certain set of labels is not defined: %v", [wl.metadata.name]),
		"packagename": "armo_builtins",
		"alertScore": 2,
		"failedPaths": path,
         "alertObject": {
			"k8sApiObjects": [wl]
		}
     }
}

# There is no label-usage in WL and also for his Pod
noLabelUsage(wl, podSpec, begginingOfPodPath) = path{
	path1 := noLabelOrNoLabelUsage(wl, "")
	path2 := noLabelOrNoLabelUsage(podSpec, begginingOfPodPath)
	path = array.concat(path1, path2)
}

# There is label-usage for WL but not for his Pod
noLabelUsage(wl, podSpec, begginingOfPodPath) = path{
	not noLabelOrNoLabelUsage(wl, "")
	path := noLabelOrNoLabelUsage(podSpec, begginingOfPodPath)
}

# There is no label-usage for WL but there is for his Pod
noLabelUsage(wl, podSpec, begginingOfPodPath) = path{
	not noLabelOrNoLabelUsage(podSpec, begginingOfPodPath)
	path := noLabelOrNoLabelUsage(wl, "")
}

noLabelOrNoLabelUsage(wl, begginingOfPath) = path{
	# TODO fix-path
	not wl.metadata
	path = [""]
}

noLabelOrNoLabelUsage(wl, begginingOfPath) = path{
	metadata := wl.metadata
	not metadata.labels
	path = [sprintf("%vmetadata", [begginingOfPath])]
}

noLabelOrNoLabelUsage(wl, begginingOfPath) = path{
	labels := wl.metadata.labels
	not isDesiredLabel(labels)
	path = [sprintf("%vmetadata.labels", [begginingOfPath])]
}

isDesiredLabel(labels) {
	_ = labels.app
}

isDesiredLabel(labels) {
	_ = labels.tier
}

isDesiredLabel(labels) {
	_ = labels.phase
}

isDesiredLabel(labels) {
	_ = labels.version
}

isDesiredLabel(labels){
	_ = labels.owner
}

isDesiredLabel(labels) {
	_ = labels.env
}
