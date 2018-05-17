---

# Important Note

The lambdas contained in this module, or at least `lambdas/notifyfailures/` specifically, contain external python modules.

In order for them to work correctly, the module(s) must be locally installed _into the lambda directory:_

```
pip install requests -t lambdas/notifyfailures/
```

The directory itself contains a .gitignore preventing git tracking those modules, hence this README.
