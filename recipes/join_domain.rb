#
# Cookbook Name:: sssd_ad
# Recipe:: join_domain
#
# Copyright 2015 Biola University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

include_recipe 'chef-vault::default'

begin
  bind_credentials = chef_vault_item(
    node['sssd_ad']['vault_name'],
    node['sssd_ad']['vault_item']
  )
rescue
  Chef::Log.warn(
    'Unable to load credentials from chef-vault item. Skipping domain join.'
  )
end

if bind_credentials
  execute "join #{node['sssd_ad']['realm']} domain" do
    command "net ads join -U #{bind_credentials['username']}@"\
            "#{node['sssd_ad']['realm']}%"\
            "'#{bind_credentials['password']}'"
    sensitive true
    not_if "getent group 'Domain Admins'"
    action :nothing # delay binding to allow Samba cookbook to configure /etc/samba/smb.conf
    subscribes :run, 'template[/etc/samba/smb.conf]'
  end
end
