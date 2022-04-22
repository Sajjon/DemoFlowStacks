//
//  DemoFlowStacksApp.swift
//  DemoFlowStacks
//
//  Created by Alexander Cyon on 2022-04-21.
//

import SwiftUI
import FlowStacks

// MARK: - APP
@main
struct DemoFlowStacksApp: App {
	var body: some Scene {
		WindowGroup {
			AppCoordinator()
				.navigationViewStyle(.stack)
				.environmentObject(AuthState())
		}
	}
}


struct User {
	struct Credentials {
		let email: String
		let password: String
	}
	struct PersonalInfo {
		let firstname: String
		let lastname: String
	}
	let credentials: Credentials
	let personalInfo: PersonalInfo
}

typealias PIN = String

final class AuthState: ObservableObject {
	@Published var user: User? = nil
	@Published var pin: PIN? = nil
	var isAuthenticated: Bool { user != nil }
	func signOut() { user = nil }
	public init() {}
}

// MARK: - App Coord.
struct AppCoordinator: View {
	enum Screen {
		case splash
		case main(user: User, pin: PIN?)
		case onboarding
	}
	@EnvironmentObject var auth: AuthState
	@State var routes: Routes<Screen> = [.root(.splash)]
	
	var body: some View {
		Router($routes) { screen, _ in
			switch screen {
			case .splash:
				SplashView(
					toOnboarding: toOnboarding,
					toMain: toMain
				)
			case let .main(user, pin):
				MainView(user: user, pin: pin, signOut: signOut)
			case .onboarding:
				OnboardingCoordinator(done: onboardingDone)
			}
		}
	}
	
	private func signOut() {
		auth.signOut()
		toOnboarding()
	}
	
	private func onboardingDone(user: User, pin: PIN?) {
		toMain(user: user, pin: pin)
	}
	
	private func toOnboarding() {
		routes = [.root(.onboarding)]
	}
	
	private func toMain(user: User, pin: PIN?) {
		routes = [.root(.main(user: user, pin: pin))]
	}
	
}

// MARK: - Splash
struct SplashView: View {
	
	@EnvironmentObject var auth: AuthState
	
	var toOnboarding: () -> Void
	var toMain: (User, PIN?) -> Void
	
	var body: some View {
		ZStack {
			Color.pink.edgesIgnoringSafeArea(.all)
			Text("SPLASH").font(.largeTitle)
		}
		.onAppear {
			
			// Simulate some loading
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
				if let user = auth.user {
					toMain(user, auth.pin)
				} else {
					toOnboarding()
				}
			}
		}
	}
}

// MARK: - Main
struct MainView: View {
	let user: User
	let pin: PIN?
	let signOut: () -> Void
	var body: some View {
		ZStack {
			Color.blue.opacity(0.65).edgesIgnoringSafeArea(.all)
			VStack {
				Text("Hello \(user.personalInfo.firstname)!")
				Button("Sign out") {
					signOut()
				}
			}
		}
		.navigationTitle("Main")
	}
}

// MARK: - Onboarding Flow
struct OnboardingCoordinator: View {
	enum Screen {
		case welcome // Screen
		case termsOfService // Screen
		case signUpFlow // Flow of multiple screens and subflows.
		case setPINflow(User) // Flow of multiple screens
	}
	let done: (User, PIN?) -> Void
	@EnvironmentObject var auth: AuthState
	@State var routes: Routes<Screen> = [.root(.welcome)]
	
	var body: some View {
		NavigationView {
			Router($routes) { screen, _ in
				switch screen {
				case .welcome:
					WelcomeView(start: toTermsOfService)
				case .termsOfService:
					TermsOfServiceView(accept: toSignUp)
				case .signUpFlow:
					NavigationView {
						SignUpFlow(signedUpUser: toSetPIN)
							.environmentObject(auth)
					}
				case .setPINflow(let user):
					NavigationView {
						SetPINFlow(user: user, doneSettingPIN: { maybePin in
							doneSettingUser(user, andPIN: maybePin)
						})
						.environmentObject(auth)
					}
				}
			}
		}
	}
	
	private func toTermsOfService() {
		routes.push(.termsOfService)
	}
	
	private func toSignUp() {
		print("🔮✍🏽 push-ing `signUpFlow`")
		routes.push(.signUpFlow)
	}
	
	private func toSetPIN(user: User) {
		print("🔮🔐 push-ing `setPINflow`")
		routes.push(.setPINflow(user))
	}
	
	private func doneSettingUser(_ user: User, andPIN pin: PIN?) {
		done(user, pin)
	}
}

// MARK: - Welcome (Onb.)
struct WelcomeView: View {
	var start: () -> Void
	var body: some View {
		ZStack {
			Color.green.opacity(0.65).edgesIgnoringSafeArea(.all)
			VStack {
				Button("Start") {
					start()
				}
			}
		}
		.buttonStyle(.borderedProminent)
		.navigationTitle("Welcome")
	}
}

// MARK: - Terms (Onb.)
struct TermsOfServiceView: View {
	var accept: () -> Void
	var body: some View {
		ZStack {
			Color.orange.opacity(0.65).edgesIgnoringSafeArea(.all)
			VStack {
				Text("We will steal your soul.")
				Button("Accept terms") {
					accept()
				}
			}
		}
		.buttonStyle(.borderedProminent)
		.navigationTitle("Terms")
	}
}

// MARK: - SignUp SubFlow (Onb.)
struct SignUpFlow: View {
	enum Screen {
		case credentials
		case personalInfo(credentials: User.Credentials)
	}
	@EnvironmentObject var auth: AuthState
	let signedUpUser: (User) -> Void
	@State var routes: Routes<Screen> = [.root(.credentials)]
	
	var body: some View {
		Router($routes) { screen, _ in
			switch screen {
			case .credentials:
				CredentialsView(next: toPersonalInfo)
			case .personalInfo(let credentials):
				PersonalInfoView(credentials: credentials, done: done)
			}
		}
	}
	
	private func toPersonalInfo(credentials: User.Credentials) {
		routes.push(.personalInfo(credentials: credentials))
	}
	
	private func done(user: User) {
		auth.user = user
		signedUpUser(user)
	}
}


// MARK: - Credentials (Onb.SignUp)
struct CredentialsView: View {
	@State var email = "jane.doe@cool.me"
	@State var password = "secretstuff"
	private var credentials: User.Credentials? {
		guard !email.isEmpty, !password.isEmpty else { return nil }
		return .init(email: email, password: password)
	}
	var next: (User.Credentials) -> Void
	var body: some View {
		ZStack {
			Color.yellow.opacity(0.65).edgesIgnoringSafeArea(.all)
			VStack {
				TextField("Email", text: $email)
				SecureField("Password", text: $password)
				
				Button("Next") {
					next(credentials!)
				}.disabled(credentials == nil)
			}
		}
		.buttonStyle(.borderedProminent)
		.textFieldStyle(.roundedBorder)
		.navigationTitle("Credentials")
	}
}

// MARK: - PersonalInfo (Onb.SignUp)
struct PersonalInfoView: View {
	@State var firstname = "Jane"
	@State var lastname = "Doe"
	let credentials: User.Credentials
	private var user: User? {
		guard !firstname.isEmpty, !lastname.isEmpty else { return nil }
		return .init(credentials: credentials, personalInfo: .init(firstname: firstname, lastname: lastname))
	}
	var done: (User) -> Void
	var body: some View {
		ZStack {
			Color.brown.opacity(0.65).edgesIgnoringSafeArea(.all)
			VStack {
				TextField("Firstname", text: $firstname)
				TextField("Lastname", text: $lastname)
				
				Button("Sign Up") {
					done(user!)
				}.disabled(user == nil)
			}
		}
		.buttonStyle(.borderedProminent)
		.textFieldStyle(.roundedBorder)
		.navigationTitle("Personal Info")
	}
}


// MARK: - SetPIN SubFlow (Onb.)
struct SetPINFlow: View {
	enum Screen {
		case pinOnce
		case confirmPIN(PIN)
	}
	@EnvironmentObject var auth: AuthState
	let user: User
	let doneSettingPIN: (PIN?) -> Void
	
	@State var routes: Routes<Screen> = [.root(.pinOnce)]
	
	var body: some View {
		Router($routes) { screen, _ in
			switch screen {
			case .pinOnce:
				InputPINView(firstname: user.personalInfo.firstname, next: toConfirmPIN, skip: skip)
			case .confirmPIN(let pinToConfirm):
				ConfirmPINView(pinToConfirm: pinToConfirm, done: done, skip: skip)
			}
		}
	}
	
	private func toConfirmPIN(pin: PIN) {
		routes.push(.confirmPIN(pin))
	}
	
	private func done(pin: PIN) {
		auth.pin = pin
		doneSettingPIN(pin)
	}
	
	private func skip() {
		doneSettingPIN(nil)
	}
}

// MARK: - InputPINView (Onb.SetPIN)
struct InputPINView: View {
	
	let firstname: String
	var next: (PIN) -> Void
	var skip: () -> Void
	
	@State var pin = "1234"
	
	var body: some View {
		ZStack {
			Color.red.opacity(0.65).edgesIgnoringSafeArea(.all)
			VStack {
				Text("Hey \(firstname), secure your app by setting a PIN.").lineLimit(2)
				SecureField("PIN", text: $pin)
				Button("Next") {
					next(pin)
				}.disabled(pin.isEmpty)
			}
		}
		.navigationTitle("Set PIN")
		.toolbar {
			ToolbarItem(placement: .navigationBarTrailing) {
				Button("Skip") {
					skip()
				}
			}
		}
		.buttonStyle(.borderedProminent)
		.textFieldStyle(.roundedBorder)
	}
}

// MARK: - ConfirmPINView (Onb.SetPIN)
struct ConfirmPINView: View {
	
	let pinToConfirm: PIN
	var done: (PIN) -> Void
	var skip: () -> Void
	
	@State var pin = "1234"
	
	var body: some View {
		ZStack {
			Color.teal.opacity(0.65).edgesIgnoringSafeArea(.all)
			VStack {
				SecureField("PIN", text: $pin)
				if pin != pinToConfirm {
					Text("Mismatch between PINs").foregroundColor(.red)
				}
				Button("Confirm PIN") {
					done(pin)
				}.disabled(pin != pinToConfirm)
			}
		}
		.navigationTitle("Confirm PIN")
		.toolbar {
			ToolbarItem(placement: .navigationBarTrailing) {
				Button("Skip") {
					skip()
				}
			}
		}
		.buttonStyle(.borderedProminent)
		.textFieldStyle(.roundedBorder)
	}
}


