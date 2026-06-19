import SwiftUI
import MoonlitCore

struct MacActorBioView: View {
    let name: String
    let tmdbPersonId: Int?

    @Environment(\.dismiss) private var dismiss
    @State private var person: PersonDetails?
    @State private var isLoading = true
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView().tint(MoonlitTheme.accent)
                        Spacer()
                    }
                    .padding(.top, 80)
                } else if let p = person {
                    bioContent(p)
                } else {
                    HStack {
                        Spacer()
                        Text(error ?? "No information available")
                            .foregroundColor(MoonlitTheme.textTertiary)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .padding(.top, 80)
                }
                Spacer().frame(height: 40)
            }
        }
        .frame(minWidth: 500, minHeight: 500)
        .background(MoonlitTheme.background)
        .navigationTitle(name)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
        .task {
            await loadPerson()
        }
    }

    // MARK: - Load

    private func loadPerson() async {
        do {
            let service = TMDBPersonService.shared
            let personId: Int?
            if let knownId = tmdbPersonId {
                personId = knownId
            } else {
                personId = try await service.personId(forName: name)
            }
            guard let id = personId else {
                isLoading = false
                return
            }
            person = try await service.personDetails(id: id)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Content

    @ViewBuilder
    private func bioContent(_ p: PersonDetails) -> some View {
        // Photo strip
        if !p.profileImages.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(p.profileImages.prefix(8), id: \.self) { path in
                        CachedAsyncImage(url: TMDBPersonService.shared.imageURL(path: path, size: "w300")) { img in
                            img.resizable().aspectRatio(2/3, contentMode: .fill)
                        } placeholder: {
                            Rectangle().fill(MoonlitTheme.surfaceElevated)
                        }
                        .frame(width: 90, height: 135)
                        .clipped()
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 16)
        }

        // Personal info
        if p.birthday != nil || p.placeOfBirth != nil || p.knownForDepartment != nil {
            VStack(alignment: .leading, spacing: 6) {
                if let birthday = p.birthday {
                    infoRow(label: "Born", value: birthday)
                }
                if let birthplace = p.placeOfBirth {
                    infoRow(label: "From", value: birthplace)
                }
                if let dept = p.knownForDepartment {
                    infoRow(label: "Known For", value: dept)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }

        // Biography
        if !p.biography.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("Biography")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                Text(p.biography)
                    .font(.subheadline)
                    .foregroundColor(MoonlitTheme.textSecondary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
            }
        }

        // Known For
        let knownFor = p.credits.knownFor
        if !knownFor.isEmpty {
            Text("Known For")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(knownFor.prefix(12)) { credit in
                        VStack(alignment: .leading, spacing: 4) {
                            CachedAsyncImage(
                                url: TMDBPersonService.shared.imageURL(path: credit.posterPath, size: "w185")
                            ) { img in
                                img.resizable().aspectRatio(2/3, contentMode: .fill)
                            } placeholder: {
                                Rectangle().fill(MoonlitTheme.surfaceElevated)
                            }
                            .frame(width: 90, height: 135)
                            .clipped()
                            .cornerRadius(8)
                            Text(credit.title)
                                .font(.caption2)
                                .foregroundColor(MoonlitTheme.textSecondary)
                                .lineLimit(2)
                                .frame(width: 90)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 32)
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundColor(MoonlitTheme.textTertiary)
                .frame(width: 70, alignment: .leading)
            Text(value)
                .font(.caption)
                .foregroundColor(.white)
        }
    }
}
