# canaria-cookbook

A library cookbook to extend the Chef DSL to include `canary?` and
`set_chef_environment` helpers. When properly configured it will allow nodes to
autonomously determine whether they're a canary and to take appropriate actions.
In my case it was developed to allow nodes to change environments for rolling
upgrades, however, it could be used to guard for any canary operations you'd like.
Most of the time it will be within 5% of the configured canary percentage, though
it does vary depending on your node count and hostname patterns.  If you
require 100% accuracy for canary nodes there is an option to whitelist them via
node FQDN.

## Controlling the canaries

The idea here is to allow nodes to autonomously decide if they are canaries,
however, there are several ways in which you can control which nodes
are canaries: hostname overrides, canary percentage, a combination of both.

If you want to specify nodes you can set the overrides manually.  If you need an
exact percentage of nodes you can do a knife search, sort, map to set the hostname
overrides.

## How the the DSL helpers work
`canary?` works by hashing the node FQDN and does a modulo over 100 to determine
which out of 100 groups the node belongs to. If nodes group is between
0 and the configured percentage it will be a canary.

Unlike `node.chef_environment`, `set_chef_environment` will verify that the
environment exists and raise an error if an invalid environment is used.

## How to use the canaria cookbook
Include `canaria` in your node's `run_list`:

```json
{
  "run_list": [
    "recipe[canaria::default]"
  ]
}
```

Configure the the percentage and overrides in your environments

```ruby
# environments/my_app_canary.rb
override_attributes(
  'canaria' => {
    'overrides' => ['host.my_org.com'],
    'percentage' => 0
  }
)
```

Use the helpers in your applications recipe

```ruby

if canary?
  # Do canary things like change into the canary environment
  set_chef_environment(node['my_app']['canary']['environment'])

  # Or maybe install the canary version of your application if you don't have
  # a separate environment
  my_app do
    version 'canary'
    action :install
  end
else
  # Or install the stable version of the package if you don't use multiple
  # environments
  my_app do
    version 'stable'
    action :install
  end
end
```

## Rolling canary environments explained
After the pipeline has gone green in the Development, Rehearsal and Union
and it's time to promote to Production, we'll first want to test our changes on
a few select canary nodes before doing a rolling upgrade out to 10%, 50% and
finally 100% percent of our applications nodes.  Because our attributes
and cookbook versions are pinned via Chef environment, we'll control the rollout
by promoting changes to our applications canary and production environments.

### Pipeline promotion steps
* Change the canary percentage attribute in our applications canary
and production environments.  Changing the value in both environments will ensure
that all canaries will stay in the canary environment.

  ```ruby
  # environments/my_app_production.rb
  cookbook_versions(
   "my_app"=>"~> 1.2.0"
  )
  override_attributes(
    'canaria' => {
      'overrides' => ['host.my_org.com'],
      'percentage' => 10
    }
  )
  ```
  ```ruby
  # environments/my_app_canary.rb
  cookbook_versions(
   "my_app"=>"~> 1.3.0"
  )
  override_attributes(
    'canaria' => {
      'overrides' => ['host.my_org.com'],
      'percentage' => 10
    }
  )
  ```

* Wait for the nodes to converge and upgrade.  You can determine a safe grace
period by summing the converge frequency, converge splay and average increase in converge length during upgrades.

* Increase canary percentage in both environments
  ```ruby
  # environments/my_app_production.rb
  cookbook_versions(
   "my_app"=>"~> 1.2.0"
  )
  override_attributes(
    'canaria' => {
      'overrides' => ['host.my_org.com'],
      'percentage' => 20
    }
  )
  ```
  ```ruby
  # environments/my_app_canary.rb
  cookbook_versions(
   "my_app"=>"~> 1.3.0"
  )
  override_attributes(
    'canaria' => {
      'overrides' => ['host.my_org.com'],
      'percentage' => 20
    }
  )
  ```

* Wait for the nodes to converge and upgrade

* Repeat the increase and wait steps until it is time to push to 100% of nodes.

* Promote our application Canary environment to Production and change the canary percentage to zero in both of our environments

  ```ruby
  # environments/my_app_production.rb
  cookbook_versions(
   "my_app"=>"~> 1.3.0"
  )
  override_attributes(
    'canaria' => {
      'overrides' => ['host.my_org.com'],
      'percentage' => 0
    }
  )
  ```
  ```ruby
  # environments/my_app_canary.rb
  cookbook_versions(
   "my_app"=>"~> 1.3.0"
  )
  override_attributes(
    'canaria' => {
      'overrides' => ['host.my_org.com'],
      'percentage' => 0
    }
  )
  ```

After the final step all nodes should eventually upgrade and join the production
environment.  In the event of a rollback, all we have to do is change the canary percentage to zero in both environments.

## Attributes

<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['canaria']['percentage']</tt></td>
    <td>Integer</td>
    <td>What percentage of nodes should be selected as canaries</td>
    <td><tt>0</tt></td>
  </tr>
  <tr>
    <td><tt>['canaria']['overrides']</tt></td>
    <td>Array</td>
    <td>An array of node FQDNs that will automatically be canaries</td>
    <td><tt>[]</tt></td>
  </tr>
</table>

## License and Authors

Author:: Ryan Cragun (<ryan@chef.io>)
