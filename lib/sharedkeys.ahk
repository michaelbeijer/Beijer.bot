; lib/sharedkeys.ahk — the API-key file shared with Supervertaler for Trados
; and Supervertaler for memoQ (Trados #108).
;
; One file, <data root>\settings\api-keys.json, one key per provider, plain
; text. The data root is where the other products keep everything, found the
; way they find it: %AppData%\Supervertaler\config.json -> "user_data_path".
;
; Reads prefer the shared file and fall back to settings.ini, so an install
; that has never seen the file keeps working; the providers window writes to
; both, so a key pasted here is a key pasted everywhere.
;
; Provider ids differ in one place: Sidekick says "anthropic", the plugins say
; "claude". Everything else - openai, gemini, mistral, deepseek, openrouter -
; is the same word. Machine-translation keys (google, microsoft, deepl,
; modernmt) are Sidekick's own and are stored under their own names.

; Path of the shared file, or "" when there is no data root to find.
SK_File() {
    cfg := EnvGet("APPDATA") "\Supervertaler\config.json"
    if !FileExist(cfg)
        return ""
    try {
        raw := FileRead(cfg, "UTF-8")
        data := Jxon_Load(&raw)
        root := (data is Map && data.Has("user_data_path")) ? Trim(data["user_data_path"]) : ""
    } catch {
        return ""
    }
    if (root = "")
        return ""
    return RTrim(root, "\") "\settings\api-keys.json"
}

; Sidekick's id for a provider -> the id the shared file uses.
SK_Id(id) {
    static alias := Map("anthropic", "claude")
    return alias.Has(id) ? alias[id] : id
}

; The whole file as a Map, empty when absent or unreadable.
SK_Load() {
    file := SK_File()
    if (file = "" || !FileExist(file))
        return Map()
    try {
        raw := FileRead(file, "UTF-8")
        data := Jxon_Load(&raw)
        return (data is Map) ? data : Map()
    } catch {
        return Map()
    }
}

; The key for a Sidekick provider id: the shared file first, settings.ini after.
SK_Key(id) {
    data := SK_Load()
    k := SK_Id(id)
    if (data.Has(k) && Trim(data[k]) != "")
        return Trim(data[k])
    return Trim(AI_Ini(SettingsFile(), "Keys", id, ""))
}

; Writes one key to the shared file (an empty key removes it). Returns true
; when written. Silent when there is no data root: settings.ini still has it.
SK_KeySet(id, key) {
    file := SK_File()
    if (file = "")
        return false
    data := SK_Load()
    k := SK_Id(id)
    key := Trim(key)
    if (key = "") {
        if data.Has(k)
            data.Delete(k)
    } else {
        data[k] := key
    }
    if !data.Has("_comment")
        data["_comment"] := "API keys shared by Supervertaler for Trados, Supervertaler for memoQ and Supervertaler Sidekick. One key per provider; edit by hand or in any product's settings."
    try {
        SplitPath(file, , &dir)
        if !DirExist(dir)
            DirCreate(dir)
        tmp := file ".tmp"
        f := FileOpen(tmp, "w", "UTF-8-RAW")
        f.Write(Jxon_Dump(data, 2))
        f.Close()
        FileMove(tmp, file, 1)
        return true
    } catch {
        return false
    }
}
