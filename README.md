# canaria-cookbook

A library cookbook is to extend the Chef DSL to include a `canary?` helper. When
properly configured it will allow nodes to make autonomous decisions based on a
consistent hashing algorithm. It was developed to allow nodes to change
environments for rolling upgrades, however, it could be used to guard for any
canary operations you'd like. Most of the time it will be within 5% of the
configured canary percentage.

### Rolling canary environments explained
After the pipeline has gone green in Development, Rehearsal and Union environments
and it's time to push out changes to nodes in Production, we first want to test
our changes on a few select canary nodes and then do a rolling upgrade out to
10%, 50% and 100% percent of all nodes.  Because our attributes and versions are
pinned in the Environment we'll first promote our changes to a Canary
environment, do a rolling upgrade, and then promote our Canary Production and
move all of nodes to Production.  We can control which nodes are canaries by
using hostname overrides, a percentage of all nodes, or a combination of both.

First, the pipeline will promote a change to our Application specific canary node
attribute overrides for a few specific hosts.

```ruby
# environments/production.rb
cookbook_versions(
 "my_app"=>"~> 1.2.0"
)
override_attributes(
  'my_app' => { 'canary' => { 'overrides' => ['host.my_org.com'] }}
)

# environments/my_app_canary.rb
cookbook_versions(
 "my_app"=>"~> 1.3.0"
)
override_attributes(
  'my_app' => { 'canary' => { 'overrides' => ['host.my_org.com'] }}
)
```

This change will be made in both the Production and application specific
canary environments.  Changing the value in both environments helps to ensure
that all canaries will stay in the canary environment.

After we've done our verification, the pipeline will promote the canary
percentage to 10%, and 50% to both environments.  These promotions could be manual
or triggered with automated verification tests.

```ruby
# environments/production.rb
cookbook_versions(
 "my_app"=>"~> 1.2.0"
)
override_attributes(
  'my_app' => { 'canary' => { 'overrides' => ['host.my_org.com'] }}
)

# environments/my_app_canary.rb
cookbook_versions(
 "my_app"=>"~> 1.3.0"
)
override_attributes(
  'my_app' => { 'canary' => {
    'overrides' => ['host.my_org.com'],
    'percentage' => 10
  }}
)
```

This process will repeat until the canary percentage is 50%, when the pipeline
will promote the final rollout by changing the canary percentage and overrides
back to default and promoting the canary environment to Production.
This will ensure that all nodes eventually migrate back to the Production
environment and those that were already there will converge with the newly
promoted changes.

```ruby
# environments/production.rb
cookbook_versions(
 "my_app"=>"~> 1.3.0"
)
override_attributes(
  'my_app' => { 'canary' => { 'overrides' => [] }}
)

# environments/my_app_canary.rb
cookbook_versions(
 "my_app"=>"~> 1.3.0"
)
override_attributes(
  'my_app' => { 'canary' => {
    'overrides' => [],
    'percentage' => 0
  }}
)
```

In the event of a rollback, all we have to do is change the canary percentage to
zero in both environments.

### How the `canary?` DSL helper works
The helper function will hash the node name and do a modulo over 100 to determine
which out of 100 groups the node belongs to. If node is an a groups is between
0 and the configured percentage it will be a canary.

### How to use it
Include `canaria` in your node's `run_list`:

```json
{
  "run_list": [
    "recipe[canaria::default]"
  ]
}
```

In your nodes application recipe set the canaria percentage attribute value.

```ruby
# recipes/canary.rb
node.set['canaria']['percent'] = node['my_app']['canary']['percent']
node.set['canaria']['overrides'] = node['my_app']['canary']['overrides']

if canary?
  # Do canary things like change into the canary environment
  node.set['chef_environment'] = node['my_app']['canary']['environment']

  # Or maybe install the canary version of your application if you don't have
  # a separate environment
  my_app do
    version 'canary'
    action :install
  end
else
  # make sure we're in prod
  node.set['chef_environment'] = 'production'

  # Or install the stable version of the package if you don't use multiple
  # environments
  my_app do
    version 'stable'
    action :install
  end
end
```

## Attributes

If you only have a single application in any given environent you could set
these at the environment level.  If you have multiple applications that share
and environment you should set these attributes to unique application specific
values.

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
