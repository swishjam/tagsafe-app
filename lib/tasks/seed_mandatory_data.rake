namespace :seed do
  task :mandatory_data => :environment do
    puts "Beginning seed."

    puts "Creating Script Test Types."
    script_test_types = ['Current Tag', 'Previous Tag', 'Without Tag']
    script_test_types.each do |name|
      unless ScriptTestType.find_by(name: name)
        ScriptTestType.create(name: name)
      end
    end 

    puts "Creating Execution Reasons."
    execution_reasons =  ['Manual Execution', 'Scheduled Execution', 'Tag Change', 'Reactivated Tag', 'Test', 'Initial Audit']
    execution_reasons.each do |name|
      unless ExecutionReason.find_by(name: name)
        ExecutionReason.create(name: name)
      end
    end

    puts "Creating lint rules"
    lint_rules = [
      { rule: "for-direction", description: "for loop update clause moving the counter in the right direction." },
      { rule: "getter-return", description: "`return` statements in getters" },
      { rule: "no-async-promise-executor", description:	"disallow using an async function as a Promise executor" },
      { rule: "no-await-in-loop", description:	"disallow `await` inside of loops" },
      { rule: "no-compare-neg-zero", description:	"disallow comparing against -0" },
      { rule: "no-cond-assign", description:	"disallow assignment operators in conditional expressions" },
      { rule: "no-console", description:	"disallow the use of `console`" },
      { rule: "no-constant-condition", description:	"disallow constant expressions in conditions" },
      { rule: "no-control-regex", description:	"disallow control characters in regular expressions" },
      { rule: "no-debugger", description:	"disallow the use of `debugger`" },
      { rule: "no-dupe-args", description:	"disallow duplicate arguments in `function` definitions" },
      { rule: "no-dupe-else-if", description:	"disallow duplicate conditions in if-else-if chains" },
      { rule: "no-dupe-keys", description:	"disallow duplicate keys in object literals" },
      { rule: "no-duplicate-case", description:	"disallow duplicate case labels" },
      { rule: "no-empty", description:	"disallow empty block statements" },
      { rule: "no-empty-character-class", description:	"disallow empty character classes in regular expressions" },
      { rule: "no-ex-assign", description:	"disallow reassigning exceptions in `catch` clauses" },
      { rule: "no-extra-boolean-cast", description:	"disallow unnecessary boolean casts" },
      { rule: "no-extra-parens", description:	"disallow unnecessary parentheses" },
      { rule: "no-extra-semi", description:	"disallow unnecessary semicolons" },
      { rule: "no-func-assign", description:	"disallow reassigning `function` declarations" },
      { rule: "no-import-assign", description:	"disallow assigning to imported bindings" },
      { rule: "no-inner-declarations", description:	"disallow variable or `function` declarations in nested blocks" },
      { rule: "no-invalid-regexp", description:	"disallow invalid regular expression strings in `RegExp` constructors" },
      { rule: "no-irregular-whitespace", description:	"disallow irregular whitespace" },
      { rule: "no-loss-of-precision", description:	"disallow literal numbers that lose precision" },
      { rule: "no-misleading-character-class", description:	"disallow characters which are made with multiple code points in character class syntax" },
      { rule: "no-obj-calls", description:	"disallow calling global object properties as functions" },
      { rule: "no-promise-executor-return", description:	"disallow returning values from Promise executor functions" },
      { rule: "no-prototype-builtins", description:	"disallow calling some `Object.prototype` methods directly on objects" },
      { rule: "no-regex-spaces", description:	"disallow multiple spaces in regular expressions" },
      { rule: "no-setter-return", description:	"disallow returning values from setters" },
      { rule: "no-sparse-arrays", description:	"disallow sparse arrays" },
      { rule: "no-template-curly-in-string", description:	"disallow template literal placeholder syntax in regular strings" },
      { rule: "no-unexpected-multiline", description:	"disallow confusing multiline expressions" },
      { rule: "no-unreachable", description:	"disallow unreachable code after `return`, `throw`, `continue`, and `break` statements" },
      { rule: "no-unreachable-loop", description:	"disallow loops with a body that allows only one iteration" },
      { rule: "no-unsafe-finally", description:	"disallow control flow statements in `finally` blocks" },
      { rule: "no-unsafe-negation", description:	"disallow negating the left operand of relational operators" },
      { rule: "no-unsafe-optional-chaining", description:	"disallow use of optional chaining in contexts where the `undefined` value is not allowed" },
      { rule: "no-useless-backreference", description:	"disallow useless backreferences in regular expressions" },
      { rule: "require-atomic-updates", description:	"disallow assignments that can lead to race conditions due to usage of `await` or `yield`" },
      { rule: "use-isnan", description:	"require calls to `isNaN()` when checking for `NaN`" },
      { rule: "valid-typeof", description:	"enforce comparing `typeof` expressions against valid strings" },
      { rule: 'init-declarations', description: 'require or disallow initialization in variable declarations' },
      { rule: 'no-delete-var',	description: 'disallow deleting variables' },
      { rule: 'no-label-var',	description: 'disallow labels that share a name with a variable' },
      { rule: 'no-restricted-globals', description: 'disallow specified global variables' },
      { rule: 'no-shadow', description: 'disallow variable declarations from shadowing variables declared in the outer scope' },
      { rule: 'no-shadow-restricted-names',	description: 'disallow identifiers from shadowing restricted names' },
      { rule: 'no-undef',	description: 'disallow the use of undeclared variables unless mentioned in `/*global */` comments' },
      { rule: 'no-undef-init',	description: 'disallow initializing variables to `undefined`' },
      { rule: 'no-undefined',	description: 'disallow the use of `undefined` as an identifier' },
      { rule: 'no-unused-vars',	description: 'disallow unused variables' },
      { rule: 'no-use-before-define',	description: 'disallow the use of variables before they are defined' },
      { rule: 'unknown', description: 'unspecified rule' }
    ]
    lint_rules.each do |lint_rule|
      rule = LintRule.find_by(rule: lint_rule[:rule])
      if rule
        rule.update(description: lint_rule[:description])
      else
        LintRule.create(rule: lint_rule[:rule], description: lint_rule[:description])
      end
    end

    performance_audit_result_metric_types = [
      { 
        key: 'DOMComplete',
        unit: 'milliseconds',
        title: 'DOM Complete'
      },
      { 
        key: 'DOMInteractive',
        unit: 'milliseconds',
        title: 'DOM Interactive'
      },
      { 
        key: 'FirstContentfulPaint',
        unit: 'milliseconds',
        title: 'First Contentful Paint'
      },
      { 
        key: 'TaskDuration',
        unit: 'milliseconds',
        title: 'Task Duration'
      },
      { 
        key: 'ScriptDuration',
        unit: 'milliseconds',
        title: 'Script Duration'
      },
      {
        key: 'LayoutDuration',
        unit: 'milliseconds',
        title: 'Layout Duration'
      }, 
      {
        key: 'TagSafeScore',
        title: 'Tag Safe Score',
        description: "Propietary TagSafe calculation for scoring a tag's performance."
      }
    ]

    puts "Creating Performance Audit Metric Types"
    performance_audit_result_metric_types.each do |metric|
      metric_type = PerformanceAuditMetricType.find_by(key: metric[:key])
      if metric_type
        metric_type.update(title: metric[:title], unit: metric[:unit], description: metric[:description])
      else
        PerformanceAuditMetricType.create(key: metric[:key], title: metric[:title], unit: metric[:unit], description: metric[:description])
      end
    end
  end
end