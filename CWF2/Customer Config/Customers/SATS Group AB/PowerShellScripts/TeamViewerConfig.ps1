$Arguments = [string[]]$(          
            ('"C:\Program Files (x86)\TeamViewer\Teamviewer.exe"'),
            ('assign'),
            ('--api-token=6389008-92GBDLzaTrTqBjgQUMNP'),
            ('--grant-easy-access')           
)


& 'cmd' '/c' ($Arguments -join ' ')