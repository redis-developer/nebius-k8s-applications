{{/*
Expand the name of the chart.
*/}}
{{- define "redis.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this
(by the DNS naming spec). If the release name contains the chart name it will be
used as the full name.
*/}}
{{- define "redis.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "redis.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "redis.labels" -}}
helm.sh/chart: {{ include "redis.chart" . }}
{{ include "redis.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "redis.selectorLabels" -}}
app: {{ include "redis.name" . }}
app.kubernetes.io/name: {{ include "redis.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Name of the Secret holding the Redis password.
*/}}
{{- define "redis.secretName" -}}
{{- printf "%s-auth" (include "redis.fullname" .) }}
{{- end }}

{{/*
Name of the PersistentVolumeClaim used for Redis data.
*/}}
{{- define "redis.pvcName" -}}
{{- printf "%s-data" (include "redis.fullname" .) }}
{{- end }}

{{/*
Resolve the Redis password.
Precedence:
  1. An explicitly provided .Values.auth.password.
  2. The password already stored in the existing Secret (preserved on upgrade).
  3. A freshly generated random password.
*/}}
{{- define "redis.password" -}}
{{- if .Values.auth.password -}}
{{- .Values.auth.password -}}
{{- else -}}
{{- $secret := (lookup "v1" "Secret" .Release.Namespace (include "redis.secretName" .)) -}}
{{- if and $secret $secret.data (hasKey $secret.data "redis-password") -}}
{{- index $secret.data "redis-password" | b64dec -}}
{{- else -}}
{{- randAlphaNum 24 -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Normalize a boolean-ish value to "true" or "" (empty).

The Nebius marketplace passes graph parameters as STRINGS, so a toggle set to
false arrives as the string "false" — which is truthy in Go templates. Pass the
value as the context and test the result with `eq ... "true"`, e.g.:
  {{- if eq (include "redis.isTrue" .Values.auth.enabled) "true" }}
This works whether the value is a real bool (true/false) or a string
("true"/"false", any case).
*/}}
{{- define "redis.isTrue" -}}
{{- if kindIs "bool" . -}}
{{- ternary "true" "" . -}}
{{- else -}}
{{- ternary "true" "" (eq (lower (toString .)) "true") -}}
{{- end -}}
{{- end -}}

{{/*
Guardrails. Rendered (and therefore evaluated) from statefulset.yaml.
Fails the render early with a clear message for unsafe configurations.
*/}}
{{- define "redis.validate" -}}
{{- if ne (int .Values.replicaCount) 1 -}}
{{- fail "This Redis chart is standalone-only and supports replicaCount=1. Multiple replicas would share a single RWO PVC (risking data corruption) or diverge behind one Service. For HA use Redis Sentinel/Cluster, which this chart does not provide." -}}
{{- end -}}
{{- $authOn := eq (include "redis.isTrue" .Values.auth.enabled) "true" -}}
{{- $override := eq (include "redis.isTrue" .Values.dangerouslyAllowUnauthenticatedExternalAccess) "true" -}}
{{- if and (not $authOn) (or (eq .Values.service.type "NodePort") (eq .Values.service.type "LoadBalancer")) (not $override) -}}
{{- fail "Refusing to expose Redis externally without authentication: auth.enabled is false and service.type is NodePort/LoadBalancer. Enable auth, use service.type=ClusterIP, or explicitly set dangerouslyAllowUnauthenticatedExternalAccess=true to override." -}}
{{- end -}}
{{- end -}}
