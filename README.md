# Multi-Domain Active Directory Search PowerShell Function

## Overview
This PowerShell function, `Search-EntireDirectory`, is designed for extensive and flexible searches across a multi-domain Active Directory forest. It can search for users, computers, and groups using various attributes like username, computer name, group name, SID, or email address. The function is particularly useful in environments with multiple domains or a complex AD structure. It also supports wildcard searches, making it ideal for broad queries.

## Functionality
- **Multi-Domain Support:** Searches across all domains in an Active Directory forest.
- **Various Search Parameters:** Search by username, computer name, group name, SID, or email address.
- **Nested Group Support:** Recursively finds members of groups, including nested groups.
- **Wildcard Searches:** Allows for broad queries using wildcard characters.
- **Log Integration:** Optional logging of search processes and results.
- **Customizable Result Set Size:** Limit the number of returned results.

## Usage Examples

### 1. Basic Search by Username
```powershell
$result = Search-EntireDirectory -Username "jdoe"
```

### 2. Search by Email Address with Wildcard
```powershell
$result = Search-EntireDirectory -EmailAddress "*@example.com"
```

### 3. Search Group Members Recursively
```powershell
$result = Search-EntireDirectory -GroupName "IT Support"
```

### 4. Search with SID
```powershell
$result = Search-EntireDirectory -ObjectSID "S-1-5-21-1234567890-123456789-1234567890-1234"
```

## Example Outputs

**Single Match:**
```plaintext
Name: John Doe
Domain: domain1.example.com
SamAccountName: jdoe
objectSid: S-1-5-21-1234567890-123456789-1234567890-1234
```

**Multiple Matches (Wildcard Search):**
```plaintext
Name: Jane Doe
Domain: domain2.example.com
Email: jane.doe@example.com

Name: John Doe
Domain: domain1.example.com
Email: john.doe@example.com
```

## Use Cases
- **Forensic Investigations:** Quickly find a user or computer across multiple domains using SID or username.
- **IT Audits:** Identify all members of a particular group, including nested group memberships.
- **Policy Enforcement:** Verify the application of policies across different domains for a given user or computer.

## Repository
Clone the script from GitHub:
```git
git clone https://github.com/ctejeda/Search-EntireDirectory.git
```

## Contributions
Contributions are encouraged to enhance the script's functionality. Feel free to fork and submit pull requests.
