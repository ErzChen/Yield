import SwiftUI

struct SpeciesRowCard: View {
    let species: SpeciesSummary
    
    var body: some View {
        HStack(spacing: Size.medium) {
            SpeciesPhoto(urlString: species.url)
                .frame(width: Size.speciesThumb, height: Size.speciesThumb)
                .clipShape(RoundedRectangle(cornerRadius: Radius.tile))
            VStack(alignment: .leading, spacing: 2) {
                Text(species.common_name)
                    .font(.besleyMedium(Font.body))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                Text(species.sci_name)
                    .font(.manropeRegular(Font.label))
                    .italic()
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(Size.small)
        .frame(maxWidth: .infinity, alignment: .leading)
        .bordered(.surface, Radius.card)
    }
}

struct AddSightingPage: View {
    @Environment(LocationManager.self) private var location
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var results: [SpeciesSummary] = []
    @State private var selected: SpeciesSummary?
    
    let spotName: String
    let onSave: (SpeciesSummary, Int) -> Void

    private var isSearching: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var localCells: [String]? {
        guard !isSearching, let coord = location.coordinate else {
            return nil
        }
        return cellIds(coord, SpeciesDatabase.maxRadius)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Size.medium) {
            header
            searchBar
            ScrollView {
                VStack(spacing: Size.small) {
                    ForEach(results) {
                        species in
                        
                        Button {
                            selected = species
                        } label: {
                            SpeciesRowCard(species: species)
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, Size.pagePadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.background)
        .navigationBarBackButtonHidden(true)
        .navigationDestination(item: $selected) {
            species in
            
            SightingInputPage(species: species) {
                amount in
                
                onSave(species, amount)
                dismiss()
            }
        }
        .toolbar {
            DismissButton()
        }
        .task(id: query) {
            if isSearching {
                try? await Task.sleep(for: .milliseconds(200))
                guard !Task.isCancelled else {
                    return
                }
            }
            let page = await SpeciesDatabase.shared.search(query, nil, 30, 0, localCells)
            guard !Task.isCancelled else {
                return
            }
            results = page
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Add sighting")
                .font(.besleyMedium(Font.title))
                .foregroundStyle(Color.textPrimary)
            Text(spotName)
                .font(.manropeRegular(Font.body))
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var searchBar: some View {
        HStack(spacing: Size.small) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: Size.iconInline))
                .foregroundStyle(Color.textSecondary)
            
            TextField("Search species", text: $query)
                .font(.manropeRegular(Font.body))
                .foregroundStyle(Color.textPrimary)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: Size.iconInline))
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
        .padding(Size.medium)
        .bordered(.surface, Radius.tile)
    }
}

struct SightingInputPage: View {
    @State private var amount: Int = 1
    @FocusState private var focused: Bool
    
    let species: SpeciesSummary
    let onSave: (Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: Size.large) {
            SpeciesRowCard(species: species)
            
            HStack {
                Text("Amount")
                    .foregroundStyle(Color.textSecondary)
                Spacer()
                HStack(spacing: Size.small) {
                    Button {
                        amount -= 1
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: Size.iconInline, weight: .semibold))
                            .frame(width: Size.tapTarget, height: Size.tapTarget)
                            .background(Color.background)
                            .clipShape(Circle())
                            .contentShape(Circle())
                    }
                    .disabled(amount <= 1)
                    .opacity(amount <= 1 ? 0.4 : 1)
                    
                    TextField("1", value: $amount, format: .number)
                        .onChange(of: amount) {
                            amount = min(max(amount, 1), 999)
                        }
                        .focused($focused)
                        .keyboardType(.numberPad)
                        .monospacedDigit()
                        .multilineTextAlignment(.center)
                        .frame(width: Size.stepperFieldWidth, height: Size.tapTarget)
                        .bordered(Color.background, Radius.tile)
                    
                    Button {
                        amount += 1
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: Size.iconInline, weight: .semibold))
                            .frame(width: Size.tapTarget, height: Size.tapTarget)
                            .background(Color.background)
                            .clipShape(Circle())
                            .contentShape(Circle())
                    }
                    .disabled(amount >= 999)
                    .opacity(amount >= 999 ? 0.4 : 1)
                }
            }
            .padding(Size.medium)
            .bordered(Color.surface, Radius.card)
            .font(.manropeBold(Font.heading))
            .foregroundStyle(Color.textPrimary)

            Button {
                onSave(amount)
            } label: {
                Text("Save sighting")
                    .font(.manropeBold(Font.body))
                    .foregroundStyle(Color.surface)
                    .frame(maxWidth: .infinity)
                    .padding(Size.medium)
                    .background {
                        RoundedRectangle(cornerRadius: Radius.tile)
                            .fill(Color.accent)
                    }
            }
            Spacer()
        }
        .padding(.horizontal, Size.pagePadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.background)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            DismissButton()
        }
    }
}
