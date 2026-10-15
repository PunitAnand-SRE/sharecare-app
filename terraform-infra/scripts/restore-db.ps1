$env:PGPASSWORD=$env:DB_PASSWORD

psql -h $env:DB_HOST -U $env:DB_USER -d charitydb -f ../dbscripts/charity.sql
psql -h $env:DB_HOST -U $env:DB_USER -d mediadb -f ../dbscripts/media.sql
psql -h $env:DB_HOST -U $env:DB_USER -d postdb -f ../dbscripts/post.sql
psql -h $env:DB_HOST -U $env:DB_USER -d userdb -f ../dbscripts/user.sql