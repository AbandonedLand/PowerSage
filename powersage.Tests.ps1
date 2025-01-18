# Import the module to be tested
. "$PSScriptRoot/powersage.ps1"

Describe "Start-SageDaemon" {
    It "Should start a job named 'SageDaemon'" {
        # Arrange
        $jobName = "SageDaemon"

        # Act
        Start-SageDaemon

        # Assert
        $job = Get-Job -Name $jobName
        $job | Should -Not -BeNullOrEmpty
        $job.Name | Should -Be $jobName

        # Cleanup
        Stop-Job -name $jobName
        Remove-Job -Name $jobName
    }
}