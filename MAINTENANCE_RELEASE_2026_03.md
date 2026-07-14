# Security Audit Findings — March 2026

## Overview

adhearsion-cpa is a Call Progress Analysis plugin for the Adhearsion telephony framework. It detects tones (beep, DTMF, fax, speech, etc.) during VoIP calls via FreeSWITCH/mod_rayo.

**Overall Risk: LOW** — small codebase (~150 lines of library code), no direct I/O, no auth handling, no deserialization.

---

## Findings

### 1. URL Injection in Grammar Construction (Medium)

**File:** `lib/adhearsion_cpa/tone_detector.rb:71-78`

Tone names and option keys/values are interpolated directly into a URL string with no validation or encoding:

```ruby
ns_url = "#{Punchblock::BASE_RAYO_NAMESPACE}:cpa:#{tone}:#{Punchblock::RAYO_VERSION}"
opts.each_with_index do |(k, v), i|
  ns_url << "?#{k}=#{v}"   # or ";#{k}=#{v}"
end
```

If a caller passes a malicious tone name like `"beep:1.0?inject=bad"` or option values containing `?`, `;`, or `&`, the constructed URL would be malformed or contain injected parameters. While this is an internal API (not directly user-facing), any code path that passes unsanitized external input to `detect_tone` could exploit this.

**Recommendation:** Validate tone names against a whitelist of known detectors. URL-encode option keys and values.

### 2. Insecure Gem Source (Low)

**File:** `Gemfile:1`

```ruby
source "http://rubygems.org"
```

Uses HTTP instead of HTTPS, making gem downloads vulnerable to MITM attacks during development.

**Recommendation:** Change to `source "https://rubygems.org"`.

### 3. Unpinned Dependencies from GitHub Forks (Low-Medium)

**File:** `Gemfile:3-4`

```ruby
gem 'adhearsion', github: "logicsys/adhearsion", branch: "develop"
gem 'punchblock', github: "logicsys/punchblock", branch: "develop"
```

Dependencies are pulled from forked GitHub repos on `develop` branches with no commit pinning. If these repos are compromised or force-pushed to, malicious code could be introduced.

**Recommendation:** Pin to specific commit SHAs or use tagged releases.

### 4. Severely Outdated Dependencies (Medium)

**File:** `adhearsion_cpa.gemspec:20-28`

- `activesupport >= 3.0.10` — allows versions with known CVEs
- `bundler ~> 1.0` — EOL, current is 2.x
- `rspec ~> 2.5` — very outdated, current is 3.x
- `coveralls >= 0` — unmaintained
- `adhearsion ~> 3.0.0.rc2` and `punchblock >= 3.0.0.rc2` — pre-release versions

Old dependencies may contain known vulnerabilities, especially `activesupport` which has had numerous security patches since 3.0.

**Recommendation:** Audit and update all dependency version constraints.

### 5. Shell Execution in Gemspec (Low)

**File:** `adhearsion_cpa.gemspec:17-18`

```ruby
s.files         = `git ls-files`.split("\n")
s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
```

Uses backtick shell execution. This is a common Ruby gem pattern but executes shell commands during gem build. Low risk since it's only invoked during packaging, not at runtime.

### 6. No Input Validation on Tone Arguments (Low)

**File:** `lib/adhearsion_cpa/controller_methods.rb:19`

The `detect_tone` method accepts arbitrary arguments with no type checking or validation. Unexpected types could cause runtime errors or unexpected behavior downstream.

### 7. Mutable State via `attr_accessor` (Low)

**File:** `lib/adhearsion_cpa/tone_detector.rb:4`

`tones` and `timeout` are exposed as writable attributes. While the class is short-lived, external mutation during detection could cause race conditions in async mode.

---

## Not Found (Good)

- No `eval`, `send`, `system`, `exec` with user input
- No file I/O or network calls (delegated to Punchblock)
- No credential handling or secret storage
- No unsafe deserialization (`Marshal.load`, `YAML.load`, etc.)
- No SQL or command injection vectors
- The `class_eval` in plugin.rb is safe (hardcoded constant inclusion)

---

## Priority Recommendations

1. **Fix Gemfile source** to HTTPS — trivial, high-value fix
2. **Whitelist tone names** in `build_grammar_for` to prevent URL injection
3. **URL-encode** option values before building grammar URLs
4. **Pin GitHub dependencies** to commit SHAs
5. **Update dependency constraints** to exclude known-vulnerable versions of activesupport

---

## Resolution — 2026-07-14

Applied during the July 2026 maintenance round:

1. **Fixed** — Gemfile source switched to `https://rubygems.org`.
2. **Fixed** — Tone names validated against `/\A[a-zA-Z0-9_-]+\z/` in
   `ToneDetector#build_grammar_for`; invalid names raise `ArgumentError`
   (spec: "with a tone name containing URL metacharacters").
3. **Fixed** — Option keys/values URL-encoded via
   `URI.encode_www_form_component` before grammar URL construction
   (spec: "with option values containing URL metacharacters").
4. **Partially addressed** — Gemfile now pins sibling forks with unpushed
   commits via local paths; pushed forks (blather, ruby_ami) remain on
   `develop` branch pins. SHA-pinning remains an option once all forks
   are pushed and tagged.
5. **Fixed** — `activesupport` constraint tightened to `~> 8.0` (matches
   adhearsion 4.x). Also added `required_ruby_version >= 3.3.0` and
   removed the obsolete `rubyforge_project` attribute.

Findings #5 (gemspec backticks — standard packaging pattern), #6 and #7
(low-severity internal-API hardening) accepted as-is.
