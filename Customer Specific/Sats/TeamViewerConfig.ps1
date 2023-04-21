$Arguments = [string[]]$(          
            ('"C:\Program Files\TeamViewer (x86)\Teamviewer.exe"'),
            ('assign'),
            ('--api-token=6389008-92GBDLzaTrTqBjgQUMNP')
            ('--grant-easy-access')
            
)


& 'cmd' '/c' ($Arguments -join ' ')