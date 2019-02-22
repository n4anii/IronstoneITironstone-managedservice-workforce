#####################################################
################ CMD ASSOC & FTYPE ##################
#####################################################


LOCATION
"C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe"

OPEN WITH
"C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe %1"

ASSOC .pdf="PDF File" FTYPE "PDF File"="C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe %1"


#####################################################
#################### INTUNE MDM #####################
#####################################################
NAME
ApplicationDefaults/DefaultAssociationsConfiguration

OMA-URI
./Device/Vendor/MSFT/Policy/Config/ApplicationDefaults/DefaultAssociationsConfiguration

STRING (BASE64)
PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPERlZmF1bHRBc3NvY2lhdGlvbnM+CiAgPEFzc29jaWF0aW9uIElkZW50aWZpZXI9Ii5wZGYiIFByb2dJZD0iQWNyb0V4Y2guRG9jdW1lbnQuREMiIEFwcGxpY2F0aW9uTmFtZT0iQWRvYmUgQWNyb2JhdCBSZWFkZXIgREMiIEFwcGx5T25VcGdyYWRlPSJ0cnVlIiBPdmVyd3JpdGVJZlByb2dJZElzPSJBY3JvRXhjaC5Eb2N1bWVudC5EQyIgLz4KICA8QXNzb2NpYXRpb24gSWRlbnRpZmllcj0iLnBkZnhtbCIgUHJvZ0lkPSJBY3JvRXhjaC5Eb2N1bWVudC5EQyIgQXBwbGljYXRpb25OYW1lPSJBZG9iZSBBY3JvYmF0IFJlYWRlciBEQyIgQXBwbHlPblVwZ3JhZGU9InRydWUiIE92ZXJ3cml0ZUlmUHJvZ0lkSXM9IkFjcm9FeGNoLkRvY3VtZW50LkRDIiAvPgogIDxBc3NvY2lhdGlvbiBJZGVudGlmaWVyPSIucGR4IiBQcm9nSWQ9IkFjcm9FeGNoLkRvY3VtZW50LkRDIiBBcHBsaWNhdGlvbk5hbWU9IkFkb2JlIEFjcm9iYXQgUmVhZGVyIERDIiBBcHBseU9uVXBncmFkZT0idHJ1ZSIgT3ZlcndyaXRlSWZQcm9nSWRJcz0iQWNyb0V4Y2guRG9jdW1lbnQuREMiIC8+CiAgPEFzc29jaWF0aW9uIElkZW50aWZpZXI9Ii54ZHAiIFByb2dJZD0iQWNyb0V4Y2guRG9jdW1lbnQuREMiIEFwcGxpY2F0aW9uTmFtZT0iQWRvYmUgQWNyb2JhdCBSZWFkZXIgREMiIEFwcGx5T25VcGdyYWRlPSJ0cnVlIiBPdmVyd3JpdGVJZlByb2dJZElzPSJBY3JvRXhjaC5Eb2N1bWVudC5EQyIgLz4KICA8QXNzb2NpYXRpb24gSWRlbnRpZmllcj0iLnhmZGYiIFByb2dJZD0iQWNyb0V4Y2guRG9jdW1lbnQuREMiIEFwcGxpY2F0aW9uTmFtZT0iQWRvYmUgQWNyb2JhdCBSZWFkZXIgREMiIEFwcGx5T25VcGdyYWRlPSJ0cnVlIiBPdmVyd3JpdGVJZlByb2dJZElzPSJBY3JvRXhjaC5Eb2N1bWVudC5EQyIgLz4KICA8QXNzb2NpYXRpb24gSWRlbnRpZmllcj0ibWFpbHRvIiBQcm9nSWQ9Ik91dGxvb2suVVJMLm1haWx0by4xNSIgQXBwbGljYXRpb25OYW1lPSJPdXRsb29rIDIwMTYiIEFwcGx5T25VcGdyYWRlPSJ0cnVlIiBPdmVyd3JpdGVJZlByb2dJZElzPSJPdXRsb29rLlVSTC5tYWlsdG8uMTUiIC8+CjwvRGVmYXVsdEFzc29jaWF0aW9ucz4=


#####################################################
#################### REG VALUES #####################
#####################################################

## Prevents EDGE asking about being set as default
DisallowDefaultBrowserPrompt
HKCU\SOFTWARE\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppContainer\Storage\microsoft.microsoftedge_8wekyb3d8bbwe\MicrosoftEdge\Main
DisallowDefaultBrowserPrompt = 1	REG_DWORD


## Prevents "open with"-dialog for PDF
HKCU\Software\Classes\AppXd4nrz8ff68srnhf9t5a8sbjyar1cr723
NoStaticDefaultVerb = (Blank)		REG_SZ

HKCU\Software\Classes\AppXd4nrz8ff68srnhf9t5a8sbjyar1cr723
NoOpenWith = (Blank)				REG_SZ

HKCU\Software\Classes\AppX4hxtad77fbk3jkkeerkrm0ze94wjf3s9
NoOpenWith = (Blank)				REG_SZ




#####################################################
#################### XML FILES ######################
#####################################################


###################################################
# Various
###################################################
<?xml version="1.0" encoding="UTF-8"?>
<DefaultAssociations>
	<Association Identifier="mailto" ProgId="Outlook.URL.mailto.15" ApplicationName="Outlook 2016" />
</DefaultAssociations>



<?xml version="1.0" encoding="UTF-8"?>
<DefaultAssociations>
  <Association Identifier=".eml" ProgId="Outlook.File.eml.14" ApplicationName="Microsoft Outlook" />
  <Association Identifier=".pdf" ProgId="AcroExch.Document.DC" ApplicationName="Adobe Acrobat Reader DC" />
  <Association Identifier="http" ProgId="IE.HTTP" ApplicationName="Internet Explorer" />
  <Association Identifier="https" ProgId="IE.HTTPS" ApplicationName="Internet Explorer" />
  <Association Identifier="mailto" ProgId="Outlook.URL.mailto.14" ApplicationName="Microsoft Outlook" />
</DefaultAssociations>



<?xml version="1.0" encoding="UTF-8"?>
<DefaultAssociations>
  <Association Identifier=".acrobatsecuritysettings" ProgId="AcroExch.acrobatsecuritysettings" ApplicationName="Adobe Reader" />
  <Association Identifier=".fdf" ProgId="AcroExch.FDFDoc" ApplicationName="Adobe Reader" />
  <Association Identifier=".htm" ProgId="IE.AssocFile.HTM" ApplicationName="Internet Explorer" />
  <Association Identifier=".html" ProgId="IE.AssocFile.HTM" ApplicationName="Internet Explorer" />
  <Association Identifier=".mht" ProgId="IE.AssocFile.MHT" ApplicationName="Internet Explorer" />
  <Association Identifier=".mhtml" ProgId="IE.AssocFile.MHT" ApplicationName="Internet Explorer" />
  <Association Identifier=".partial" ProgId="IE.AssocFile.PARTIAL" ApplicationName="Internet Explorer" />
  <Association Identifier=".pdf" ProgId="AcroExch.Document.11" ApplicationName="Adobe Reader" />
  <Association Identifier=".pdfxml" ProgId="AcroExch.pdfxml" ApplicationName="Adobe Reader" />
  <Association Identifier=".pdx" ProgId="PDXFileType" ApplicationName="Adobe Reader" />
  <Association Identifier=".svg" ProgId="IE.AssocFile.SVG" ApplicationName="Internet Explorer" />
  <Association Identifier=".url" ProgId="IE.AssocFile.URL" ApplicationName="Internet Browser" />
  <Association Identifier=".website" ProgId="IE.AssocFile.WEBSITE" ApplicationName="Internet Explorer" />
  <Association Identifier=".xdp" ProgId="AcroExch.XDPDoc" ApplicationName="Adobe Reader" />
  <Association Identifier=".xfdf" ProgId="AcroExch.XFDFDoc" ApplicationName="Adobe Reader" />
  <Association Identifier=".xht" ProgId="IE.AssocFile.XHT" ApplicationName="Internet Explorer" />
  <Association Identifier=".xhtml" ProgId="IE.AssocFile.XHT" ApplicationName="Internet Explorer" />
  <Association Identifier="acrobat" ProgId="acrobat" ApplicationName="Adobe Reader" />
  <Association Identifier="ftp" ProgId="IE.FTP" ApplicationName="Internet Explorer" />
  <Association Identifier="http" ProgId="IE.HTTP" ApplicationName="Internet Explorer" />
  <Association Identifier="https" ProgId="IE.HTTPS" ApplicationName="Internet Explorer" />
  <Association Identifier="mk" ProgId="IE.HTTP" ApplicationName="Internet Explorer" />
  <Association Identifier="res" ProgId="IE.HTTP" ApplicationName="Internet Explorer" />
</DefaultAssociations>



###################################################
# OEM DEFAULT XML from Windows 16299.241
# C:\windows\system32\OEMDefaultAssociations.xml'
###################################################
<?xml version="1.0" encoding="UTF-8"?>
<DefaultAssociations>
  <Association Identifier=".3g2" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" ApplyOnUpgrade="true" OverwriteIfProgId
Is="AppXhjhjmgrfm2d7rd026az898dy2p1pcsyt;WMP11.AssocFile.3G2" />
  <Association Identifier=".3gp" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" ApplyOnUpgrade="true" OverwriteIfProgId
Is="AppXhjhjmgrfm2d7rd026az898dy2p1pcsyt;WMP11.AssocFile.3GP" />
  <Association Identifier=".3gp2" ProgId="WMP11.AssocFile.3G2" ApplicationName="Windows Media Player" />
  <Association Identifier=".3gpp" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" ApplyOnUpgrade="true" OverwriteIfProgI
dIs="AppXhjhjmgrfm2d7rd026az898dy2p1pcsyt;WMP11.AssocFile.3GP" />
  <Association Identifier=".3mf" ProgId="AppX4r6v2fg5b2qwg1jprp713smfp4wb02yp" ApplicationName="View 3D" ApplyOnUpgrade="true" OverwriteIfProgIdIs="AppX
vhc4p7vz4b485xfp46hhk3fq3grkdgjg;AppXr0rz9yckydawgnrx5df1t9s57ne60yhn"  />
  <Association Identifier=".aac" ProgId="AppXqj98qxeaynz6dv4459ayz6bnqxbyaqcs" ApplicationName="Music" ApplyOnUpgrade="true" OverwriteIfProgIdIs="WMP11.
AssocFile.ADTS" />
  <Association Identifier=".ac3" ProgId="AppXqj98qxeaynz6dv4459ayz6bnqxbyaqcs" ApplicationName="Music" ApplyOnUpgrade="true" />
  <Association Identifier=".adt" ProgId="AppXqj98qxeaynz6dv4459ayz6bnqxbyaqcs" ApplicationName="Music" ApplyOnUpgrade="true" OverwriteIfProgIdIs="WMP11.
AssocFile.ADTS" />
  <Association Identifier=".adts" ProgId="AppXqj98qxeaynz6dv4459ayz6bnqxbyaqcs" ApplicationName="Music" ApplyOnUpgrade="true" OverwriteIfProgIdIs="WMP11
.AssocFile.ADTS" />
  <Association Identifier=".amr" ProgId="AppXqj98qxeaynz6dv4459ayz6bnqxbyaqcs" ApplicationName="Music" ApplyOnUpgrade="true" />
  <Association Identifier=".arw" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" ApplyOnUpgrade="true" OverwriteIfProgIdIs="AppX9
vdwcvrwnbettpahnt26jswq0n8hgyah;Paint.Paint;Microsoft.PhotoManager.imagetype" />
  <Association Identifier=".avi" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" ApplyOnUpgrade="true" OverwriteIfProgId
Is="AppXhjhjmgrfm2d7rd026az898dy2p1pcsyt;WMP11.AssocFile.AVI" />
  <Association Identifier=".bmp" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" ApplyOnUpgrade="true" OverwriteIfProgIdIs="AppX9
vdwcvrwnbettpahnt26jswq0n8hgyah;Paint.Paint;Microsoft.PhotoManager.imagetype;Paint.Picture" />
  <Association Identifier=".cr2" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" ApplyOnUpgrade="true" OverwriteIfProgIdIs="AppX9
vdwcvrwnbettpahnt26jswq0n8hgyah;Paint.Paint;Microsoft.PhotoManager.imagetype" />
  <Association Identifier=".crw" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" ApplyOnUpgrade="true" OverwriteIfProgIdIs="AppX9
vdwcvrwnbettpahnt26jswq0n8hgyah;Paint.Paint;Microsoft.PhotoManager.imagetype" />
  <Association Identifier=".dib" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" ApplyOnUpgrade="true" OverwriteIfProgIdIs="AppX9
vdwcvrwnbettpahnt26jswq0n8hgyah;Paint.Paint;Microsoft.PhotoManager.imagetype;Paint.Picture" />
  <Association Identifier=".ec3" ProgId="AppXqj98qxeaynz6dv4459ayz6bnqxbyaqcs" ApplicationName="Music" ApplyOnUpgrade="true" />
  <Association Identifier=".epub" ProgId="AppXvepbp3z66accmsd0x877zbbxjctkpr6t" ApplicationName="Microsoft Edge" ApplyOnUpgrade="true" />
  <Association Identifier=".erf" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" ApplyOnUpgrade="true" OverwriteIfProgIdIs="AppX9
vdwcvrwnbettpahnt26jswq0n8hgyah;Paint.Paint;Microsoft.PhotoManager.imagetype" />
  <Association Identifier=".fbx" ProgId="AppX4r6v2fg5b2qwg1jprp713smfp4wb02yp" ApplicationName="View 3D" ApplyOnUpgrade="true" />
  <Association Identifier=".flac" ProgId="AppXqj98qxeaynz6dv4459ayz6bnqxbyaqcs" ApplicationName="Music" ApplyOnUpgrade="true" />
  <Association Identifier=".gif" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" ApplyOnUpgrade="true" OverwriteIfProgIdIs="AppX9
vdwcvrwnbettpahnt26jswq0n8hgyah;Paint.Paint;Microsoft.PhotoManager.imagetype;giffile" />
  <Association Identifier=".glb" ProgId="AppX4r6v2fg5b2qwg1jprp713smfp4wb02yp" ApplicationName="View 3D" ApplyOnUpgrade="true" />
  <Association Identifier=".gltf" ProgId="AppX4r6v2fg5b2qwg1jprp713smfp4wb02yp" ApplicationName="View 3D" ApplyOnUpgrade="true" />
  <Association Identifier=".htm" ProgId="AppX4hxtad77fbk3jkkeerkrm0ze94wjf3s9" ApplicationName="Microsoft Edge" ApplyOnUpgrade="true" OverwriteIfProgIdI
s="AppX6k1pws1pa7jjhchyzw9jce3e6hg6vn8d" />
  <Association Identifier=".html" ProgId="AppX4hxtad77fbk3jkkeerkrm0ze94wjf3s9" ApplicationName="Microsoft Edge" ApplyOnUpgrade="true" OverwriteIfProgId
Is="AppX6k1pws1pa7jjhchyzw9jce3e6hg6vn8d" />
  <Association Identifier=".jfif" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" ApplyOnUpgrade="true" OverwriteIfProgIdIs="AppX
9vdwcvrwnbettpahnt26jswq0n8hgyah;Paint.Paint;Microsoft.PhotoManager.imagetype;pjpegfile" />
  <Association Identifier=".jpe" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" ApplyOnUpgrade="true" OverwriteIfProgIdIs="AppX9
vdwcvrwnbettpahnt26jswq0n8hgyah;Paint.Paint;Microsoft.PhotoManager.imagetype;jpegfile" />
  <Association Identifier=".jpeg" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" ApplyOnUpgrade="true" OverwriteIfProgIdIs="AppX
9vdwcvrwnbettpahnt26jswq0n8hgyah;Paint.Paint;Microsoft.PhotoManager.imagetype;jpegfile" />
  <Association Identifier=".jpg" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" ApplyOnUpgrade="true" OverwriteIfProgIdIs="AppX9
vdwcvrwnbettpahnt26jswq0n8hgyah;Paint.Paint;Microsoft.PhotoManager.imagetype;jpegfile" />
  <Association Identifier=".jxr" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" ApplyOnUpgrade="true" OverwriteIfProgIdIs="AppX9
vdwcvrwnbettpahnt26jswq0n8hgyah;Paint.Paint;Microsoft.PhotoManager.imagetype;wdpfile" />
  <Association Identifier=".kdc" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" ApplyOnUpgrade="true" OverwriteIfProgIdIs="AppX9
vdwcvrwnbettpahnt26jswq0n8hgyah;Paint.Paint;Microsoft.PhotoManager.imagetype" />
  <Association Identifier=".m2t" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" ApplyOnUpgrade="true" OverwriteIfProgId
Is="WMP11.AssocFile.M2TS" />
  <Association Identifier=".m2ts" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" ApplyOnUpgrade="true" OverwriteIfProgI
dIs="WMP11.AssocFile.M2TS" />
  <Association Identifier=".m3u" ProgId="AppXqj98qxeaynz6dv4459ayz6bnqxbyaqcs" ApplicationName="Music" ApplyOnUpgrade="true" />
  <Association Identifier=".m4a" ProgId="AppXqj98qxeaynz6dv4459ayz6bnqxbyaqcs" ApplicationName="Music" ApplyOnUpgrade="true" OverwriteIfProgIdIs="WMP11.
AssocFile.M4A" />
  <Association Identifier=".m4r" ProgId="AppXqj98qxeaynz6dv4459ayz6bnqxbyaqcs" ApplicationName="Music" ApplyOnUpgrade="true" />
  <Association Identifier=".m4v" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" ApplyOnUpgrade="true" OverwriteIfProgId
Is="AppXhjhjmgrfm2d7rd026az898dy2p1pcsyt;WMP11.AssocFile.MP4"/>
  <Association Identifier=".mka" ProgId="AppXqj98qxeaynz6dv4459ayz6bnqxbyaqcs" ApplicationName="Music" ApplyOnUpgrade="true" OverwriteIfProgIdIs="WMP11.
AssocFile.MKA"/>
  <Association Identifier=".mkv" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" ApplyOnUpgrade="true" />
  <Association Identifier=".mod" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" ApplyOnUpgrade="true" OverwriteIfProgId
Is="WMP11.AssocFile.MPEG" />
  <Association Identifier=".mov" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" ApplyOnUpgrade="true" OverwriteIfProgId
Is="AppXhjhjmgrfm2d7rd026az898dy2p1pcsyt;WMP11.AssocFile.MOV" />
  <Association Identifier=".mrw" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" ApplyOnUpgrade="true" OverwriteIfProgIdIs="AppX9
vdwcvrwnbettpahnt26jswq0n8hgyah;Paint.Paint;Microsoft.PhotoManager.imagetype" />
  <Association Identifier=".MP2" ProgId="WMP11.AssocFile.MP3" ApplicationName="Windows Media Player" />
  <Association Identifier=".mp3" ProgId="AppXqj98qxeaynz6dv4459ayz6bnqxbyaqcs" ApplicationName="Music" ApplyOnUpgrade="true" OverwriteIfProgIdIs="WMP11.
AssocFile.MP3" />
  <Association Identifier=".mp4" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" ApplyOnUpgrade="true" OverwriteIfProgId
Is="AppXhjhjmgrfm2d7rd026az898dy2p1pcsyt;WMP11.AssocFile.MP4" />
  <Association Identifier=".mp4v" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" ApplyOnUpgrade="true" OverwriteIfProgI
dIs="AppXhjhjmgrfm2d7rd026az898dy2p1pcsyt;WMP11.AssocFile.MP4" />
  <Association Identifier=".mpa" ProgId="AppXqj98qxeaynz6dv4459ayz6bnqxbyaqcs" ApplicationName="Music" ApplyOnUpgrade="true" OverwriteIfProgIdIs="WMP11.
AssocFile.MPEG" />
  <Association Identifier=".MPE" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" ApplyOnUpgrade="true" OverwriteIfProgId
Is="WMP11.AssocFile.MPEG" />
  <Association Identifier=".mpeg" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" ApplyOnUpgrade="true" OverwriteIfProgI
dIs="WMP11.AssocFile.MPEG" />
  <Association Identifier=".mpg" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" ApplyOnUpgrade="true" OverwriteIfProgId
Is="WMP11.AssocFile.MPEG" />
  <Association Identifier=".mpv2" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" ApplyOnUpgrade="true" OverwriteIfProgI
dIs="WMP11.AssocFile.MPEG" />
  <Association Identifier=".mts" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" ApplyOnUpgrade="true" OverwriteIfProgId
Is="WMP11.AssocFile.M2TS" />
  <Association Identifier=".nef" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" ApplyOnUpgrade="true" OverwriteIfProgIdIs="AppX9
vdwcvrwnbettpahnt26jswq0n8hgyah;Paint.Paint;Microsoft.PhotoManager.imagetype" />
  <Association Identifier=".nrw" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" ApplyOnUpgrade="true" OverwriteIfProgIdIs="AppX9
vdwcvrwnbettpahnt26jswq0n8hgyah;Paint.Paint;Microsoft.PhotoManager.imagetype" />
  <Association Identifier=".obj" ProgId="AppX4r6v2fg5b2qwg1jprp713smfp4wb02yp" ApplicationName="View 3D" ApplyOnUpgrade="true" />
  <Association Identifier=".orf" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" ApplyOnUpgrade="true" OverwriteIfProgIdIs="AppX9
vdwcvrwnbettpahnt26jswq0n8hgyah;Paint.Paint;Microsoft.PhotoManager.imagetype" />
  <Association Identifier=".oxps" ProgId="Windows.XPSReachViewer" ApplicationName="XPS Viewer" ApplyOnUpgrade="true" OverwriteIfProgIdIs="AppX86746z2101
ayy2ygv3g96e4eqdf8r99j" />
  <Association Identifier=".pdf" ProgId="AppXd4nrz8ff68srnhf9t5a8sbjyar1cr723" ApplicationName="Microsoft Edge" ApplyOnUpgrade="true" OverwriteIfProgIdI
s="AppXk660crfh0gw7gd9swc1nws708mn7qjr1;AppX86746z2101ayy2ygv3g96e4eqdf8r99j" />
  <Association Identifier=".pef" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" ApplyOnUpgrade="true" OverwriteIfProgIdIs="AppX9
vdwcvrwnbettpahnt26jswq0n8hgyah;Paint.Paint;Microsoft.PhotoManager.imagetype" />
  <Association Identifier=".ply" ProgId="AppX4r6v2fg5b2qwg1jprp713smfp4wb02yp" ApplicationName="View 3D" ApplyOnUpgrade="true" />
  <Association Identifier=".png" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" ApplyOnUpgrade="true" OverwriteIfProgIdIs="AppX9
vdwcvrwnbettpahnt26jswq0n8hgyah;Paint.Paint;Microsoft.PhotoManager.imagetype;pngfile" />
  <Association Identifier=".raf" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" ApplyOnUpgrade="true" OverwriteIfProgIdIs="AppX9
vdwcvrwnbettpahnt26jswq0n8hgyah;Paint.Paint;Microsoft.PhotoManager.imagetype" />
  <Association Identifier=".raw" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" ApplyOnUpgrade="true" OverwriteIfProgIdIs="AppX9
vdwcvrwnbettpahnt26jswq0n8hgyah;Paint.Paint;Microsoft.PhotoManager.imagetype" />
  <Association Identifier=".rw2" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" ApplyOnUpgrade="true" OverwriteIfProgIdIs="AppX9
vdwcvrwnbettpahnt26jswq0n8hgyah;Paint.Paint;Microsoft.PhotoManager.imagetype" />
  <Association Identifier=".rwl" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" ApplyOnUpgrade="true" OverwriteIfProgIdIs="AppX9
vdwcvrwnbettpahnt26jswq0n8hgyah;Paint.Paint;Microsoft.PhotoManager.imagetype" />
  <Association Identifier=".tif" ProgId="PhotoViewer.FileAssoc.Tiff" ApplicationName="Windows Photo Viewer" ApplyOnUpgrade="true" OverwriteIfProgIdIs="A
ppX86746z2101ayy2ygv3g96e4eqdf8r99j;AppX9vdwcvrwnbettpahnt26jswq0n8hgyah;TIFImage.Document" />
  <Association Identifier=".tiff" ProgId="PhotoViewer.FileAssoc.Tiff" ApplicationName="Windows Photo Viewer" ApplyOnUpgrade="true" OverwriteIfProgIdIs="
AppX86746z2101ayy2ygv3g96e4eqdf8r99j;AppX9vdwcvrwnbettpahnt26jswq0n8hgyah;TIFImage.Document" />
  <Association Identifier=".tod" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" ApplyOnUpgrade="true" />
  <Association Identifier=".sr2" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" ApplyOnUpgrade="true" OverwriteIfProgIdIs="AppX9
vdwcvrwnbettpahnt26jswq0n8hgyah;Paint.Paint;Microsoft.PhotoManager.imagetype" />
  <Association Identifier=".srw" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" ApplyOnUpgrade="true" OverwriteIfProgIdIs="AppX9
vdwcvrwnbettpahnt26jswq0n8hgyah;Paint.Paint;Microsoft.PhotoManager.imagetype" />
  <Association Identifier=".stl" ProgId="AppX4r6v2fg5b2qwg1jprp713smfp4wb02yp" ApplicationName="View 3D" ApplyOnUpgrade="true" OverwriteIfProgIdIs="AppX
vhc4p7vz4b485xfp46hhk3fq3grkdgjg;AppXr0rz9yckydawgnrx5df1t9s57ne60yhn"  />
  <Association Identifier=".TS" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" ApplyOnUpgrade="true" OverwriteIfProgIdI
s="WMP11.AssocFile.TTS" />
  <Association Identifier=".TTS" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" ApplyOnUpgrade="true" OverwriteIfProgId
Is="WMP11.AssocFile.TTS" />
  <Association Identifier=".txt" ProgId="txtfile" ApplicationName="Notepad" />
  <Association Identifier=".url" ProgId="IE.AssocFile.URL" ApplicationName="Internet Explorer" />
  <Association Identifier=".wav" ProgId="AppXqj98qxeaynz6dv4459ayz6bnqxbyaqcs" ApplicationName="Music" ApplyOnUpgrade="true" OverwriteIfProgIdIs="WMP11.
AssocFile.WAV" />
  <Association Identifier=".wdp" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" ApplyOnUpgrade="true" OverwriteIfProgIdIs="AppX9
vdwcvrwnbettpahnt26jswq0n8hgyah;Paint.Paint;Microsoft.PhotoManager.imagetype" />
  <Association Identifier=".website" ProgId="IE.AssocFile.WEBSITE" ApplicationName="Internet Explorer" />
  <Association Identifier=".wm" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" ApplyOnUpgrade="true" OverwriteIfProgIdI
s="AppXhjhjmgrfm2d7rd026az898dy2p1pcsyt;WMP11.AssocFile.ASF" />
  <Association Identifier=".wma" ProgId="AppXqj98qxeaynz6dv4459ayz6bnqxbyaqcs" ApplicationName="Music" ApplyOnUpgrade="true" OverwriteIfProgIdIs="WMP11.
AssocFile.WMA" />
  <Association Identifier=".wmv" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" ApplyOnUpgrade="true" OverwriteIfProgId
Is="AppXhjhjmgrfm2d7rd026az898dy2p1pcsyt;WMP11.AssocFile.WMV" />
  <Association Identifier=".WPL" ProgId="AppXqj98qxeaynz6dv4459ayz6bnqxbyaqcs" ApplicationName="Music" ApplyOnUpgrade="true" OverwriteIfProgIdIs="WMP11.
AssocFile.WPL" />
  <Association Identifier=".xps" ProgId="Windows.XPSReachViewer" ApplicationName="XPS Viewer" ApplyOnUpgrade="true" OverwriteIfProgIdIs="AppX86746z2101a
yy2ygv3g96e4eqdf8r99j" />
  <Association Identifier=".xvid" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" ApplyOnUpgrade="true" />
  <Association Identifier=".zpl" ProgId="AppXqj98qxeaynz6dv4459ayz6bnqxbyaqcs" ApplicationName="Music" ApplyOnUpgrade="true" />
  <Association Identifier="bingmaps" ProgId="AppXp9gkwccvk6fa6yyfq3tmsk8ws2nprk1p" ApplicationName="Maps" ApplyOnUpgrade="true" OverwriteIfProgIdIs="App
Xde453qzh223ys1wt2jpyxz3z4cn10ngt;AppXsmrmb683pb8qxt0pktr3q27hkbyjm8sb" />
  <Association Identifier="http" ProgId="AppXq0fevzme2pys62n3e0fbqa7peapykr8v" ApplicationName="Microsoft Edge" ApplyOnUpgrade="true" OverwriteIfProgIdI
s="AppXehk712w0hx4w5b8k25kg808a9h84jamg" />
  <Association Identifier="https" ProgId="AppX90nv6nhay5n6a98fnetv7tpk64pp35es" ApplicationName="Microsoft Edge" ApplyOnUpgrade="true" OverwriteIfProgId
Is="AppXz8ws88f5y0y5nyrw1b3pj7xtm779tj2t" />
  <Association Identifier="mailto" ProgId="AppXydk58wgm44se4b399557yyyj1w7mbmvd" ApplicationName="Mail" ApplyOnUpgrade="true" />
  <Association Identifier="mswindowsmusic" ProgId="AppXtggqqtcfspt6ks3fjzyfppwc05yxwtwy" ApplicationName="Music" ApplyOnUpgrade="true" />
  <Association Identifier="mswindowsvideo" ProgId="AppX6w6n4f8xch1s3vzwf3af6bfe88qhxbza" ApplicationName="Movies &amp; TV" ApplyOnUpgrade="true" />
</DefaultAssociations>

