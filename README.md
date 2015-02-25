## canaria-cookbook: Library helper function for Canary rollout

### Abstract
The goal of the cookbook is to allow nodes to autonomously change environments
for rolling upgrades, however it could be used to guard for any canary logic
you'd like. Most of the time it will be within 5% of the desired percentage.

### My use case (but it's not limited to this use case)
When it comes time to push out changes to nodes in prod after the pipeline has
gone green in dev/qa/staging, we want to push out changes to a few select canary
nodes, then roll out to 1%, 10%, 50% and 100% respectively.  We do this by promoting
changes to the overrides and percentage in the prod and canary environments.

Frist, the pipeline will promote a change to our app canary overrides for a few
specific hosts in the prod and canary environments.  This ensures all canaries
stay in the canary environment.

After we've done our verification, the pipeline will promote the canary
percentage to 1%, 10%, and 50% to both environments, all requiring manual approval.

After 50% have been verified, the pipeline will promote the final rollout by
changing the canary percentage and overrides back to 0 and [] for both
environments, and promoting the canary environment to prod.  This will ensure that all
nodes eventually migrate back to the prod environment and those that were already
there will converge with the newly promoted environment.

In the event of a rollback, all we have to do is change the canary percentage to
zero in both environments.

### How it works
The helper function will hash the node name and do a mod of the percentage to
determine if it should be a canary.

### How to use it
Include `canaria` in your node's `run_list`:

```json
{
  "run_list": [
    "recipe[canaria::default]"
  ]
}
```

In your nodes canary recipe set the canaria percentage attribute value.  You
could directly set this attribute, however not doing so will allow you use the
helper for many different types of nodes in a shared environment.

```ruby
# recipes/canary.rb
node.set['canaria']['percent'] = node['my_app']['canary']['percent']
node.set['canaria']['overrides'] = node['my_app']['canary']['overrides']

if canary?
  # Do canary things like change into the canary environment
  node.set['chef_environment'] = 'myapp_canary'

  # Or maybe install the canary version of your application if you don't have
  # a separate environment
  my_app do
    version 'canary'
    action :install
  end
end
```

## Attributes

<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['canaria']['percent']</tt></td>
    <td>Integer</td>
    <td>What percentage of nodes should be selected as canaries</td>
    <td><tt>0</tt></td>
  </tr>
  <tr>
    <td><tt>['canaria']['override_nodes']</tt></td>
    <td>Array</td>
    <td>An array of node FQDNs that will automatically be canaries</td>
    <td><tt>[]</tt></td>
  </tr>
</table>

## License and Authors

Author:: Ryan Cragun (<ryan@chef.io>)
