import csv

input_file = r'c:\Code\ai-first-workspace-template-main\Docs\SalesAndMarketing\User Research\Leads June-October.csv'
output_file = 'statuses_dump.txt'

try:
    with open(input_file, 'r', encoding='utf-8-sig') as f:
        reader = csv.reader(f, delimiter=';')
        next(reader) # skip header
        statuses = set()
        for row in reader:
            if len(row) > 2:
                statuses.add(row[2])
    
    with open(output_file, 'w', encoding='utf-8') as f:
        for s in sorted(statuses):
            f.write(s + '\n')
    print("Success")
except Exception as e:
    print(f"Error: {e}")
