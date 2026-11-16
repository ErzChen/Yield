import SwiftUI

struct Domain: Identifiable, Hashable {
    let id: String
    let title: String
    let image: String
}

struct SearchTrigger: Equatable {
    let query: String
    let domainId: String?
}

struct LibraryTab: View {
    @Environment(LocationManager.self) private var location
    
    @State private var query = ""
    @State private var results: [SpeciesSummary] = []
    @State private var selectedDomain: Domain?
    @State private var reachedEnd = false
    @State private var isLoadingMore = false
    @FocusState private var searchFocused: Bool
    
    private let pageSize = 30
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
        NavigationStack {
            VStack() {
                searchBar
                ScrollView {
                    VStack(spacing: Size.regPadding) {
                        // Opening page content
                        if !isSearching && selectedDomain == nil {
                            Text("Browse by domain")
                                .font(.besleyBold(Font.libraryTitle))
                                .foregroundStyle(Color.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible(), spacing: Size.smallSpacing),
                                    GridItem(.flexible(), spacing: Size.smallSpacing)
                                ],
                                
                            ) {
                                domainCard(Domain(id: "fungi",  title: "Fungi",   image: "domain-fungi"))
                                domainCard(Domain(id: "plant",  title: "Plants",  image: "domain-plants"))
                                domainCard(Domain(id: "animal", title: "Animals", image: "domain-animals"))
                                domainCard(Domain(id: "fish",   title: "Fish",    image: "domain-fish"))
                            }
                            
                            Text("All species")
                                .font(.besleyBold(Font.libraryTitle))
                                .foregroundStyle(Color.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        // Domain content
                        if let domain = selectedDomain {
                            Button {
                                results = []
                                selectedDomain = nil
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "chevron.left")
                                    Text(domain.title)
                                }
                                .font(.besleyBold(Font.libraryTitle))
                                .foregroundStyle(Color.accent)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        
                        // Species list
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: Size.smallSpacing),
                                GridItem(.flexible(), spacing: Size.smallSpacing)
                            ],
                        ) {
                            ForEach(results) {
                                species in
                                
                                NavigationLink(value: species) {
                                    SpeciesCard(
                                        urlString: species.url,
                                        commonName: species.common_name,
                                        sciName: species.sci_name
                                    )
                                    .onAppear {
                                        loadMoreIfLast(species)
                                    }
                                }
                            }
                        }
                        
                    }
                }
            }
            .padding(.horizontal, Size.regPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationDestination(for: SpeciesSummary.self) {
                species in
                
                SpeciesDetailView(species: species)
            }

        }
        .task(id: SearchTrigger(query: query, domainId: selectedDomain?.id)) {
            await loadFirstPage()
        }
    }
    
    private func loadMoreIfLast(_ species: SpeciesSummary) {
        guard species.id == results.last?.id, !reachedEnd, !isLoadingMore else {
            return
        }
        isLoadingMore = true
        let currentQuery = query
        Task {
            let page = await SpeciesDatabase.shared.search(currentQuery, selectedDomain?.id, pageSize, results.count, localCells)
            if currentQuery == query {
                results += page
                reachedEnd = page.count < pageSize
            }
            isLoadingMore = false
        }
    }
    
    private func loadFirstPage() async {
        if isSearching {
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled else {
                return
            }
        }
        
        let page = await SpeciesDatabase.shared.search(query, selectedDomain?.id, pageSize, 0, localCells)
        guard !Task.isCancelled else {
            return
        }
        results = page
        reachedEnd = page.count < pageSize
    }
    
    private func domainCard(_ domain: Domain) -> some View {
        return Button {
            selectedDomain = domain
        } label: {
            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: Size.domainHeight)
                .background {
                    Image(domain.image)
                        .resizable()
                        .scaledToFill()
                }
                .overlay {
                    LinearGradient(
                        colors: [.clear, Color.black.opacity(0.75)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                }
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading) {
                        Text(domain.title)
                            .font(.besleyBold(Font.domainName))
                        HStack(spacing: 4) {
                            Text("Browse")
                                .font(.manropeBold(Font.domainSubtitle))
                            Image(systemName: "arrow.right")
                                .font(.system(size: Font.domainSubtitle, weight: .bold))
                        }
                    }
                    .foregroundStyle(Color.background)
                    .padding(Size.regPadding)
                }
                .clipShape(RoundedRectangle(cornerRadius: Radius.card))
                .overlay {
                    RoundedRectangle(cornerRadius: Radius.card).strokeBorder(Color.border, lineWidth: 1)
                }
                .appShadow()
        }
        .buttonStyle(.plain)
    }
    
    private var searchBar: some View {
        HStack(spacing: Size.smallPadding) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.textSecondary)
            
            TextField("Search \(selectedDomain?.title.lowercased() ?? "species")", text: $query)
                .font(Font.manropeRegular(Font.spotText))
                .foregroundStyle(Color.textPrimary)
                .focused($searchFocused)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
        .padding(Size.regPadding)
        .background {
            RoundedRectangle(cornerRadius: Radius.tile)
                .fill(Color.surface)
                .strokeBorder(Color.border, lineWidth: 1)
        }
    }
}
