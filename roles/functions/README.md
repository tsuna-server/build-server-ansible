# functions
This role is assumed that only load from other tasks with include_role and tasks_from like blow.

```
- name: Create an endpoint
  include_role:
    name: functions
    tasks_from: create_endpoint.yml
```

