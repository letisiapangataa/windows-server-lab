# Role-Based Access Control (RBAC) Model

## Overview
This lab uses a least-privilege RBAC model with Active Directory groups and delegated permissions.

## Group Structure
- **Domain Admins**: Full control
- **Helpdesk**: Password resets, basic user management
- **Staff**: Standard user access
- **IT Operations**: GPO management, monitoring

## Delegation
- Delegate OU control to Helpdesk for user management
- Restrict GPO editing to IT Operations

## Best Practices
- Use security groups for access control
- Regularly review group memberships
- Document all delegated permissions
