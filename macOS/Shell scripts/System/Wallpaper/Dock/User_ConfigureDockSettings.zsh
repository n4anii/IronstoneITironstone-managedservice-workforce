<?xml version="1.0" encoding="utf-8"?>
<policyDefinitions revision="1.0" schemaVersion="1.0">
  <policyNamespaces>
    <target prefix="Ironstone" namespace="Custom.b1613af0-002a-44cf-801b-dd461117b9cc" />
    <using prefix="windows" namespace="Microsoft.Policies.Windows" />
  </policyNamespaces>
  <supersededAdm fileName="ShowFileExtension.adm" />
  <resources minRequiredRevision="1.0" />
  <supportedOn>
    <definitions>
      <definition name="SUPPORTED_ProductOnly" displayName="$(string.SUPPORTED_ProductOnly)" />
      <definition name="SUPPORTED_NotSpecified" displayName="$(string.ADMXMigrator_NoSupportedOn)" />
    </definitions>
  </supportedOn>
  <categories>
    <category name="ForceShowFile" displayName="$(string.ForceShowFile)" explainText="$(string.ShowFileExtensionsExplanation)" />
  </categories>
  <policies>
    <policy name="ShowFileExtensions" class="Machine" displayName="$(string.ShowFileExtensions)" explainText="$(string.ShowFileExtensionsExplanation)" presentation="$(presentation.ShowFileExtensions)" key="Software\Microsoft\Windows NT\CurrentVersion\NetworkList\DefaultMediaCost" valueName="Ethernet">
      <parentCategory ref="ForceShowFile" />
      <supportedOn ref="SUPPORTED_ProductOnly" />
      <enabledValue>
        <decimal value="0" />
      </enabledValue>
      <disabledValue>
        <decimal value="1" />
      </disabledValue>
    </policy>
    <policy name="ShowFileExtensions_1" class="Machine" displayName="$(ShowFileExtensions_1)" explainText="$(string.ShowFileExtensionsExplanation)" presentation="$(presentation.ShowFileExtensions_1)" key="Software\Microsoft\Windows NT\CurrentVersion\NetworkList\DefaultMediaCost" valueName="WiFi">
      <parentCategory ref="ForceShowFile" />
      <supportedOn ref="SUPPORTED_ProductOnly" />
      <enabledValue>
        <decimal value="0" />
      </enabledValue>
      <disabledValue>
        <decimal value="1" />
      </disabledValue>
    </policy>
  </policies>
</policyDefinitions>