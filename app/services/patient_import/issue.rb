module PatientImport
  class Issue < Data.define(:field, :code, :severity)
    ERROR = "error"
    WARNING = "warning"

    def error?
      severity == ERROR
    end
  end
end
