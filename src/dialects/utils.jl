function check_version(dialect::String, ver::VersionNumber)
    is_compat = check_version(Bool, dialect, ver)
    if !is_compat
        spec_ver = spec_versions[dialect]
        @warn "workflow file version $(ver) might not be compatible with the toolchain version $(spec_ver) for dialect $(dialect)."
    end
    return
end
function check_version(::Type{Bool}, dialect::String, ver::VersionNumber)
    if !haskey(spec_versions, dialect)
        # if it is unregistered dialect, disable version check for it.
        @debug "version info for dialect \"$(dialect)\" not found in dialect registry \"dialects.toml\"."
        return true
    end
    spec_ver = spec_versions[dialect]
    ver.major == spec_ver.major && ver.minor <= spec_ver.minor || return false
    ver.major == 0 && ver.minor == spec_ver.minor || return false
    return true
end
