#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2024, Chad Pritchett
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: truenas_incus_exec

short_description: Execute commands in Incus instances on TrueNAS SCALE

version_added: "1.0.0"

description:
    - Execute commands inside Incus containers or VMs on TrueNAS SCALE 25.04+
    - Uses the TrueNAS API /virt/instance/{id}/exec endpoint
    - This module should be contributed to github.com/cpritchett/ansible-truenas

options:
    name:
        description:
            - Name of the Incus instance
        required: true
        type: str
    command:
        description:
            - Command to execute (can be string or list)
        required: true
        type: raw
    creates:
        description:
            - Path to file/directory that must exist for command to run
        required: false
        type: str
    removes:
        description:
            - Path to file/directory that must not exist for command to run
        required: false
        type: str
    chdir:
        description:
            - Change to this directory before executing command
        required: false
        type: str
    timeout:
        description:
            - Command timeout in seconds
        default: 300
        type: int
    environment:
        description:
            - Environment variables to set
        required: false
        type: dict

extends_documentation_fragment:
    - arensb.truenas.truenas

author:
    - Chad Pritchett (@cpritchett)
'''

EXAMPLES = r'''
# Install packages in container
- name: Install Matchbox
  truenas_incus_exec:
    name: matchbox
    command: |
      apt-get update
      apt-get install -y wget systemd
      wget https://github.com/poseidon/matchbox/releases/download/v0.10.0/matchbox-v0.10.0-linux-amd64.tar.gz
      tar xzf matchbox-v0.10.0-linux-amd64.tar.gz
      mv matchbox-v0.10.0-linux-amd64/matchbox /usr/local/bin/
    creates: /usr/local/bin/matchbox

# Run command with environment variables
- name: Configure application
  truenas_incus_exec:
    name: app-container
    command: /app/configure.sh
    environment:
      APP_ENV: production
      DB_HOST: 10.0.5.50

# Check if file exists
- name: Check configuration
  truenas_incus_exec:
    name: matchbox
    command: test -f /etc/matchbox/config.yaml
  register: config_exists
  ignore_errors: yes
'''

RETURN = r'''
stdout:
    description: Standard output from the command
    type: str
    returned: always
    sample: "Installation complete"
stderr:
    description: Standard error from the command
    type: str
    returned: always
    sample: ""
rc:
    description: Return code from the command
    type: int
    returned: always
    sample: 0
changed:
    description: Whether the command was executed
    type: bool
    returned: always
'''

from ansible.module_utils.basic import AnsibleModule
import json
import shlex


def get_instance_id(module, api_url, headers, name):
    """Get instance ID by name"""
    url = f"{api_url}/virt/instance"
    
    try:
        response = module.run_command(
            ['curl', '-s', '-k', '-H', f'Authorization: {headers["Authorization"]}', url],
            check_rc=False
        )
        
        if response[0] == 0:
            instances = json.loads(response[1])
            for instance in instances:
                if instance.get('name') == name:
                    return instance.get('id')
    except Exception as e:
        module.fail_json(msg=f"Failed to get instance ID: {str(e)}")
    
    return None


def check_path_exists(module, api_url, headers, instance_id, path):
    """Check if a path exists in the container"""
    command = f"test -e {shlex.quote(path)}"
    result = execute_command(module, api_url, headers, instance_id, command, timeout=10)
    return result['rc'] == 0


def execute_command(module, api_url, headers, instance_id, command, timeout=300, environment=None, chdir=None):
    """Execute command in instance"""
    url = f"{api_url}/virt/instance/{instance_id}/exec"
    
    # Build the command
    if isinstance(command, str):
        # Wrap in shell for complex commands
        cmd_list = ["/bin/sh", "-c", command]
    else:
        cmd_list = command
    
    # Add chdir if specified
    if chdir:
        shell_cmd = f"cd {shlex.quote(chdir)} && {command}"
        cmd_list = ["/bin/sh", "-c", shell_cmd]
    
    payload = {
        'command': cmd_list,
        'wait_for_websocket': False,
        'interactive': False,
        'timeout': timeout
    }
    
    if environment:
        payload['environment'] = environment
    
    try:
        # Using direct API call since module.run_command doesn't handle complex payloads well
        import requests
        import urllib3
        urllib3.disable_warnings()
        
        response = requests.post(
            url,
            headers=headers,
            json=payload,
            verify=False,
            timeout=timeout + 10
        )
        
        if response.status_code == 200:
            result = response.json()
            return {
                'stdout': result.get('stdout', ''),
                'stderr': result.get('stderr', ''),
                'rc': result.get('return', 0)
            }
        else:
            return {
                'stdout': '',
                'stderr': f"API call failed: {response.text}",
                'rc': 1
            }
            
    except Exception as e:
        return {
            'stdout': '',
            'stderr': str(e),
            'rc': 1
        }


def main():
    module_args = dict(
        name=dict(type='str', required=True),
        command=dict(type='raw', required=True),
        creates=dict(type='str', required=False),
        removes=dict(type='str', required=False),
        chdir=dict(type='str', required=False),
        timeout=dict(type='int', default=300),
        environment=dict(type='dict', required=False),
        api_url=dict(type='str', required=False),
        api_key=dict(type='str', required=False, no_log=True)
    )
    
    module = AnsibleModule(
        argument_spec=module_args,
        supports_check_mode=True
    )
    
    # Get API connection details
    api_url = module.params.get('api_url', 'https://localhost/api/v2.0')
    api_key = module.params.get('api_key')
    
    if not api_key:
        module.fail_json(msg="api_key is required")
    
    headers = {
        'Authorization': f'Bearer {api_key}',
        'Content-Type': 'application/json'
    }
    
    name = module.params['name']
    command = module.params['command']
    creates = module.params.get('creates')
    removes = module.params.get('removes')
    chdir = module.params.get('chdir')
    timeout = module.params['timeout']
    environment = module.params.get('environment')
    
    # Get instance ID
    instance_id = get_instance_id(module, api_url, headers, name)
    
    if not instance_id:
        module.fail_json(msg=f"Instance '{name}' not found")
    
    # Check creates/removes conditions
    if creates:
        if check_path_exists(module, api_url, headers, instance_id, creates):
            module.exit_json(
                changed=False,
                stdout="",
                stderr="",
                rc=0,
                msg=f"Path {creates} already exists, skipping command"
            )
    
    if removes:
        if not check_path_exists(module, api_url, headers, instance_id, removes):
            module.exit_json(
                changed=False,
                stdout="",
                stderr="",
                rc=0,
                msg=f"Path {removes} does not exist, skipping command"
            )
    
    # Execute the command
    if not module.check_mode:
        result = execute_command(
            module, api_url, headers, instance_id,
            command, timeout, environment, chdir
        )
        
        module.exit_json(
            changed=True,
            stdout=result['stdout'],
            stderr=result['stderr'],
            rc=result['rc'],
            failed=(result['rc'] != 0)
        )
    else:
        module.exit_json(
            changed=True,
            stdout="",
            stderr="",
            rc=0,
            msg="Command would be executed (check mode)"
        )


if __name__ == '__main__':
    main()