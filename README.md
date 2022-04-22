# Flow

```
AppCoordinator

            Main <---------------*
          /    |                  \
Splash ->{     {Sign Out}          \
          \   /                     \
            OnboardingCoordinator    \   
                - Welcome             \
                - TermsOfService       \
                - SignUpCoordinator     |
                    - Credentials       | 
                    - PersonalInfo      |
                - SetupPINCoordinator   |
                    - InputPIN         /
                    - ConfirmPIN ->---*
```