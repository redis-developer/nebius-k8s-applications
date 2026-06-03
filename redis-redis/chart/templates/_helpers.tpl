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
