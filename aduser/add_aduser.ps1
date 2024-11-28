# CSVファイルのパスを指定
$csvFilePath = "C:\scripts\users.csv"

# CSVファイルを読み込み
$users = Import-Csv -Path $csvFilePath

foreach ($user in $users) {
    try {
        # OUが存在するか確認
        $ouExists = Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$($user.OU)'" -ErrorAction SilentlyContinue
        if (-not $ouExists) {
            Write-Host "エラー: OU '$($user.OU)' が見つかりません。" -ForegroundColor Red
            continue
        }

        # ユーザー存在確認 (UserPrincipalName)
        $existingUserByUPN = Get-ADUser -Filter "UserPrincipalName -eq '$($user.UserPrincipalName)'" -ErrorAction SilentlyContinue

        # ユーザー存在確認 (姓 + 名)
        $existingUserByName = Get-ADUser -Filter "Surname -eq '$($user.LastName)' -and GivenName -eq '$($user.FirstName)'" -ErrorAction SilentlyContinue

        if ($existingUserByUPN) {
            Write-Host "ユーザー '$($user.UserPrincipalName)' は既に存在します（UserPrincipalName による一致）。" `
                "OU: $($existingUserByUPN.DistinguishedName)" -ForegroundColor Yellow
            continue
        } elseif ($existingUserByName) {
            Write-Host "ユーザー '$($user.FirstName) $($user.LastName)' は既に存在します（姓・名の組み合わせによる一致）。" `
                "OU: $($existingUserByName.DistinguishedName)" -ForegroundColor Yellow
            continue
        }

        # 新しいユーザーを作成
        New-ADUser -Name "$($user.FirstName) $($user.LastName)" `
                   -GivenName $user.FirstName `
                   -Surname $user.LastName `
                   -UserPrincipalName $user.UserPrincipalName `
                   -EmailAddress $user.EmailAddress `
                   -SamAccountName ($user.UserPrincipalName.Split("@")[0]) `
                   -AccountPassword (ConvertTo-SecureString $user.Password -AsPlainText -Force) `
                   -Enabled $true `
                   -Path $user.OU `
                   -PostalCode $user.PostalCode `
                   -PasswordNeverExpires $false `
                   -ChangePasswordAtLogon $false `
                   -Title $user.Title `
                   -Department $user.Department `
                   -Company $user.Company

        Write-Host "ユーザー '$($user.FirstName) $($user.LastName)' を作成しました。" -ForegroundColor Green

        # 作成後に少し待機
        Start-Sleep -Seconds 2

        # ProxyAddresses の設定
        $proxyAddress = "SMTP:$($user.EmailAddress)"
        $adUser = Get-ADUser -Filter "UserPrincipalName -eq '$($user.UserPrincipalName)'" -ErrorAction SilentlyContinue
        if ($adUser) {
            Set-ADUser -Identity $adUser.SamAccountName -Add @{ProxyAddresses = $proxyAddress}
            Write-Host "ユーザー '$($user.FirstName) $($user.LastName)' に ProxyAddresses を設定しました。" -ForegroundColor Cyan
        } else {
            Write-Host "エラー: ProxyAddresses を設定するためのユーザー '$($user.UserPrincipalName)' が見つかりません。" -ForegroundColor Red
        }

        # グループにユーザーを追加
        if ($adUser) {
            $groupName = $user.Group

            # セキュリティグループかどうか確認
            $group = Get-ADGroup -Filter "Name -eq '$groupName'" -ErrorAction SilentlyContinue

            if ($group) {
                Add-ADGroupMember -Identity $group -Members $adUser.SamAccountName
                Write-Host "ユーザー '$($user.FirstName) $($user.LastName)' をセキュリティグループ '$groupName' に追加しました。" -ForegroundColor Cyan
            } else {
                Write-Host "エラー: セキュリティグループ '$groupName' が見つかりません。" -ForegroundColor Red
            }
        }
    } catch {
        Write-Host "エラー: $_" -ForegroundColor Red
    }
}

pause
