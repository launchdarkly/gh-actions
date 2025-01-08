package launchdarkly

default allow = false                               # unless otherwise defined, allow is false

allow = true if {                                      # allow is true if...
    count(violation) == 0                           # there are zero violations.
}

# The golang cyclonedx tool puts licenses under 'evidence'
violation[component["bom-ref"]] = {"dependency": component["bom-ref"], "license": license} if {
  component := input.components[_]
  license := component.evidence.licenses[_].license.id
  contains(license, "GPL") # should catch GPL, LGPL, AGPL, etc
}

# The Node cyclonedx tool puts licenses directly under the component
violation[component["bom-ref"]] = {"dependency": component["bom-ref"], "license": license} if {
  component := input.components[_]
  license := component.licenses[_].license.id
  contains(license, "GPL") # should catch GPL, LGPL, AGPL, etc
}
