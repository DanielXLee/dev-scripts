# 学习 Anthos

➜  ~ gcloud auth login
Your browser has been opened to visit:

    https://accounts.google.com/o/oauth2/auth?response_type=code&....g&code_challenge_method=S256

You are now logged in as [xxxx@test.com].
Your current project is [None].  You can change this setting by running:
  $ gcloud config set project PROJECT_ID

➜  ~ gcloud auth list
  Credentialed Accounts
ACTIVE  ACCOUNT
*       xxxx@test.com

To set the active account, run:
    $ gcloud config set account `ACCOUNT`

➜  ~ gcloud config set project your-project
Updated property [core/project].
➜  ~ gcloud iam service-accounts list
DISPLAY NAME                            EMAIL                                                                 DISABLED
danielxlee                              danielxlee@your-project.iam.gserviceaccount.com                         False

➜  ~ gcloud iam service-accounts keys create key.json --iam-account=danielxlee@your-project.iam.gserviceaccount.com
created key [ab69f34344f0566ace711224f98a904ad86c2dbc] of type [json] as [key.json] for [danielxlee@your-project.iam.gserviceaccount.com]
➜  ~ cat key.json
{
  "type": "service_account",
  "project_id": "your-project",
  "private_key_id": "ab69f34344f0566ace710934f98a904ad86c2dbc",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDNYGbsmJudFfGS\nl21TGn3+5cegXHN8utAkGSNDO1dVnAKdLgWf81TVqVHWhZQMznOxWnFwYOMmjjPz\ndPFfl8lQglMmZupjIQCUfXZea2P9Q0bIs3o/uDsJku64ljE8HxJCJLBjLblBmvee\n6xegGEBfim/MXKngE4abhuoFojZ6xujsh53q+sxzStdB393UaI2JqdO5X3m3QAYo\n1MlDTlkFrrHtXEOaQfsFPvNh+weTFBB3Go00B79Cn7bWxGPI65Phy5g+yqh9VDoT\nsMRhVZm4Te3a82+wuZgvjTbD12x2AWgbU16U/fz9hnvjnFvQRgxiIcGmmmnT5Z0M\nD6r11BQtAgMBAAECggEAKdXnYW681ETyDrB1/qW44MGh5pKum8vaNmBAhKOD6NZ8\n2dPUJX8F2vhAyXgwbmNnwcrwrLmvy9zPzFoYCSb8RUAm+/2e5U6FtbnQ8O7jUWXw\n91VII869h/e8VTGTGfIiYALlQ26+/BQ7OM4e4+fMxSmIGJMPr6uKkgfrh/ZBLsUU\npjiZd0Whq+QguUbEHLbUCKZ9txdN2w1YC/zvSkVZN0LmrJyYhLOUSCaQgDauhjCg\nRhnVStz7CiaX/yEZq7Xdut0wFneSk0ZOQCMPlRXGHq4oqKMRt1kTavAlCIPK2nkv\nlVIhx0ar7nt3ptLuD7T2+a9MTVnJnb+0Wd1aFLcYqQKBgQDmz8qfomwK3I+5C6VY\nyotkv6tdViQJT2/A0WYPuig4UHVX2yTk0bZvK0eMlrrXcA9fAaZL8IwHCR6vV+Pf\nIy4Iz6vweT+Gz+P0MAKPzckn9ohkWXi5TXjZ1tThKzFK5wSyfnlNBZ8T5Ub9a3Oy\n9CxBSdTfSxrJUM5hBeXqOygQXwKBgQDjygb6/NRirTWGp+n0J4fF9z1Gr4iCMa0B\nFnH/nsRqo5RwcJOMBWeFo9XejXFhQ4sCx63LbscLgOwunrn/UfM1YNfD7b4yTljP\nhsRDYKEhoXlOUDPBHkfcwm091/2fzvUnKdbnE8qx7B3HrYijSViZ1qLoezbHJDiF\nqxUoqXe28wKBgDQHQQCNB1fHcipfQq1qMtPKFOHcShFDM8i+Kwh+iRRwppLgVkey\nMjKLCfzZ+VIY844R/B+AIMBxQNZ7tGUXNAhOb86sNjK4aAUiUWGDHMYCX6pnNLxo\nh0Zrk98R8nGU880cj1FaZAqDE2aKszDys4sgDnkrH+WjbnIWd0Y+gYB3AoGBAKmA\nSOd1QZlX6E+WHVooHDkse/VgYwT2cBUyHYwoGWJ87NUqgDCeSOVB/8BGogrNVuCv\ns1yAxy6BNb6PMDqUQZUDxique2w1rpJmZx74BY7f+ENVHN3kaXcVWnK9iaXkO7pz\nwM1cheUVnSdbsyRGTN7Uv46dOSrAgiq9HtaOHF4PAoGBAJvVLzHlhCH9yrKKXpVG\nMMYZ1CY21hs65y0NPRe5p0/29frDS3rMxM9RSOst2xslqkoTVAUtWTOuBmYW6/4y\ncT18A7OrK08CkH5VV27BZatsvErQjyP1Xea1pxAh1lmKViMm2pgxOCDuBk6J3O9u\nAwzALCWK7et5JPbOv1tofEcq\n-----END PRIVATE KEY-----\n",
  "client_email": "danielxlee@your-project.iam.gserviceaccount.com",
  "client_id": "110113188968923896159",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/virgil%40virgil-project.iam.gserviceaccount.com"
}


gcloud container hub memberships register tencent-cluster-1 \
            --context=cls-429kyua1-100018061140-context-default \
            --service-account-key-file=/Users/danielxlee/key.json \
            --kubeconfig=/Users/danielxlee/tencent.config \
            --project=virgil-project
