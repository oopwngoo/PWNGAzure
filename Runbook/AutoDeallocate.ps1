<#
    .DESCRIPTION
        Dieses Runbook hängt die heruntergefahrenen virtuellen Maschine ab.
        Die Herstellung der Verbindung wurde aus dem Tutorial Skript kopiert.
    .NOTES
        AUTHOR:     Dominik Gstöhl
        LASTEDIT:   Apr 28, 2017
#>
<#
    TODO:
        Wenn mehrere Ressourcengruppen verwendet werden sollten,
        muss man die VM Namen um die Ressourcengruppe Erweitern.
        Aktuell: "AS-SRV-GPU-01;AS-SRV-CPU-01"
        Mit Ressourcengruppen:"AnimationsStudio.AS-SRV-CPU-01;AnimationsStudio.AS-SRV-GPU-01"
#>
$STATUSstopped="PowerState/stopped"

$connectionName = "AzureRunAsConnection"
try
{
    # Stellt die Verbindung mit Azure her
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

    "Logge in Azure ein..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint | Out-Null
    Write-Output("____________________________________")   
}
catch {
    #Gibt einen Error aus, wenn es einen Verbindungsfehler gibt
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Verbindung $connectionName nicht gefunden."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
    #Beendet das Skript wenn die Verbindung zu Azure nicht aufgebaut werden kann
    exit
}

#Lade die Ressourcengruppe "AnimationsStudio"
$ResourceGroup = "AnimationsStudio"
#Lade die Automatisierungsvariable "AutoDetach"
#Diese beinhaltet die Namen der virtuellen Maschinen mit einem Semikolon getrennt
$VirtualMachines = $(Get-AutomationVariable -Name 'AutoDetach') -split ';'

foreach ($VirtualMachine in $VirtualMachines)
{   
    Write-Output("VM: " + $VirtualMachine)

    #Statusinformation der virtuellen Maschine laden
    $VMDetail=Get-AzureRmVM `
		-Name $VirtualMachine `
		-ResourceGroupName $ResourceGroup `
        -Status
    
    foreach($VMStatus in $VMDetail.Statuses){
        #Den Power Status abfragen
        if($VMStatus.Code -like "PowerState/*"){
            Write-Output("PowerStatus: " + $VMStatus.Code)
            #Falls der Power Status stopped ist, die Maschine beenden
            if($VMStatus.Code -eq $STATUSstopped){
                Write-Output("Maschine beenden...")
                #Informationen der virtuellen Maschine laden
                $VM=Get-AzureRmVM `
                    -Name $VirtualMachine `
                    -ResourceGroupName $ResourceGroup `
                    -Status
                if(($VM | Stop-AzureRmVM -Force).IsSuccessStatusCode){
                    Write-Output("Maschine wurde erfolgreich beendet.")
                } else{
                    Write-Error("Es ist ein Problem aufgetreten.")
                }
            }
        }
    }
    Write-Output("____________________________________")    
} 
Write-Output ("Fertig")
