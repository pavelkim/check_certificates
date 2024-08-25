#shellcheck shell=sh

Describe "Actual SSL certificate info retrieval functions"

  Include ../check_certificates.sh

  Describe "check_https_certificate_dates()"

    Parameters
      "example.com"               "ok"    "success"
      "mail.com"                  "ok"    "success"
      "imaginary-domain-9000.com" "error" "failure"
    End

    It "Probes web servers for SSL certificate for $1"
      When call check_https_certificate_dates "$1"
        The output should include "$1"
        The output should match pattern "$1*$2"
        The status should be "$3"
    End
  End

End