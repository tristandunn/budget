import js from "@eslint/js";
import stylistic from "@stylistic/eslint-plugin";

export default [
  {
    "ignores": [
      "app/assets/builds/**",
      "app/assets/config/manifest.js",
      "node_modules/**",
      "vendor/**"
    ]
  },
  {
    "files": ["**/*.js"],
    "languageOptions": {
      "globals": {
        "document": "readonly",
        "localStorage": "readonly",
        "window": "readonly"
      },
      "parserOptions": {
        "sourceType": "module"
      }
    },
    "plugins": {
      "@stylistic": stylistic
    },
    "rules": {
      ...js.configs.recommended.rules,
      ...stylistic.configs["all"].rules,

      "@stylistic/array-element-newline": ["error", "consistent"],
      "@stylistic/function-call-argument-newline": ["error", "consistent"],
      "@stylistic/function-paren-newline": ["error", "consistent"],
      "@stylistic/indent": [
        "error",
        2,
        {
          "VariableDeclarator": {
            "const": 3,
            "let": 2,
            "var": 2
          }
        }
      ],
      "@stylistic/lines-around-comment": ["error", { "allowClassStart": true }],
      "@stylistic/no-multi-spaces": "off",
      "@stylistic/object-curly-spacing": ["error", "always"],
      "@stylistic/padded-blocks": "off",
      "@stylistic/space-before-function-paren": "off",
      "arrow-body-style": ["error", "always"],
      "no-magic-numbers": ["error", { "ignore": [0, 1, 2, 3] }],
      "sort-keys": "error"
    }
  },
  {
    "files": ["spec/**/*.js"],
    "languageOptions": {
      "globals": {
        "afterEach": "readonly",
        "beforeEach": "readonly",
        "context": "readonly",
        "describe": "readonly",
        "expect": "readonly",
        "global": "readonly",
        "it": "readonly",
        "sinon": "readonly"
      }
    },
    "rules": {
      "no-magic-numbers": "off"
    }
  }
];
