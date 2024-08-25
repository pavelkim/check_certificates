#shellcheck shell=sh

Describe "Auxilary functions"

  Include ../check_certificates.sh

  Describe "date_to_epoch()"
    It "Converts 'Oct 10 00:00:00 2023 GMT' to UNIX epoch"
      When call date_to_epoch "Oct 10 00:00:00 2023 GMT"
      The output should include "1696896000"
    End
  End

  Describe "epoch_to_date()"
    It "Converts 'Oct 10 00:00:00 2023 GMT' to UNIX epoch"
      When call epoch_to_date "1696896000"
      The output should include "2023-10-10 02:00:00"
    End
  End
End