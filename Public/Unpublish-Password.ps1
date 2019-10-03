function Unpublish-Password {
    <#
    .SYNOPSIS
    Removes the password from public pwpush.com or a private instance of Password Pusher by using a full link or a combination of server and password.
    .DESCRIPTION
    This complements Peter Giacomo Lombardo's genius idea of sending a temporary link to password instead of plaintext (https://github.com/pglombardo/PasswordPusher).
    By default will work against publicly hosted instance at https://pwpush.com, but can use your privately hosted instance by specifying the target as script parameter.
    .NOTES
    Mostly useful in automation with deferred password auth/use, e.g. domain join of prestaged computers.
    .PARAMETER Link
    Link to remove password from in full https://pwpush.com/p/a1b2c3d4e5f6g7h8 form. Will append .json automatically.
    Can be aliased as -l
    .PARAMETER LinkId
    Only the ID of the password to remove. Builds the full link to retrieve password from based on $Server parameter, defaulting to https://pwpush.com
    Can be aliased as -i
    .PARAMETER Server
    Specifies server/service to use in FQDN format, assumes https:// protocol prefix and port 443.
    Defaults to public pwpush.com
    Can be aliased as -s
    .EXAMPLE 
    $pwdlink | Unpublish-Password

    Removes the password from the specified link.
    .EXAMPLE
    Unpublish-Password -LinkId zfleolo322wev3au

    Removes the password with LinkId "zfleolo322wev3au" on https://pwpush.com.
    #>

    param (
        [Parameter(Position=0,Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)][Alias("l")]
            [ValidatePattern("^(http[s]?)(?:\:\/\/)([\w_-]+(?:(?:\.[\w_-]+)+))(?:\/p\/)([\w]+)")]$Uri,
        [Parameter(ParameterSetName="Ref",Position=0,Mandatory=$true,ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)][Alias("p")]
            [ValidatePattern("^([\w]+)$")][string]$LinkId,
        [Parameter(ParameterSetName="Ref")][Alias("s")]
            [ValidatePattern("^([\w_-]+(?:(?:\.[\w_-]+)+))^")][string]$Server="pwpush.com"
        )
    
    # Build the Uri to kill from based on what parameters are passed
    switch ($psCmdlet.ParameterSetName) {
        "Link" {$Uri = $Link}
        "Ref" {$Uri = "https://$Server/p/$PasswordId"}
    }
    
    # Kill the password
    try {
        $Reply = Invoke-RestMethod -Method 'Delete' -Uri "$Uri.json"
        # There's a bug currently in the API that returns DELETE result as HTTP/500, generating an error - we catch that in the next block
        # When it's fixed, the next line would eval deletion
        if ($Reply.deleted) {Write-Host "Unpublished the password successfully from $Uri (or it had been deleted already)"}
    } catch {
        if ($_.Exception -notmatch '500') {
            Write-Error "Error removing the password"
        } elseif ((ConvertFrom-Json $_.ErrorDetails).deleted) {
            # Catching the HTTP/500 response
            Write-Host "Unpublished the password successfully from $Uri (or it had been deleted already)"
            Write-Host -ForegroundColor Yellow "You seem to be using an outdated version of pwpusher that returns successful deletion as HTTP/500 error.`nPlease update from https://github.com/pglombardo/PasswordPusher"
        }
    }
}

New-Alias ubpwd Unpublish-Password