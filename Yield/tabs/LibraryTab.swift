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
                    VStack(spacing: Size.medium) {
                        // Opening page content
                        if !isSearching && selectedDomain == nil {
                            Text("Browse by domain")
                                .font(.besleyMedium(Font.heading))
                                .foregroundStyle(Color.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible(), spacing: Size.small),
                                    GridItem(.flexible(), spacing: Size.small)
                                ],
                                spacing: Size.small
                            ) {
                                domainCard(Domain(id: "fungi",  title: "Fungi",   image: "domain-fungi"))
                                domainCard(Domain(id: "plant",  title: "Plants",  image: "domain-plants"))
                                domainCard(Domain(id: "animal", title: "Animals", image: "domain-animals"))
                                domainCard(Domain(id: "fish",   title: "Fish",    image: "domain-fish"))
                            }
                            
                            Text("All species")
                                .font(.besleyMedium(Font.heading))
                                .foregroundStyle(Color.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        // Domain content
                        if let domain = selectedDomain {
                            Button {
                                results = []
                                selectedDomain = nil
                            } label: {
                                HStack(spacing: Size.small) {
                                    Image(systemName: "chevron.left")
                                    Text(domain.title)
                                }
                                .font(.besleyMedium(Font.heading))
                                .foregroundStyle(Color.accent)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        
                        // Species list
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: Size.small),
                                GridItem(.flexible(), spacing: Size.small)
                            ],
                                spacing: Size.small
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
                .scrollIndicators(.hidden)
            }
            .padding(.horizontal, Size.pagePadding)
            .padding(.bottom, Size.pagePadding)
            .background(Color.background)
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
        let currentDomain = selectedDomain?.id
        Task {
            let page = await SpeciesDatabase.shared.search(currentQuery, currentDomain, pageSize, results.count, localCells)
            if currentQuery == query && currentDomain == selectedDomain?.id {
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
                        colors: [.clear, Color.overlayStrong],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                }
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading) {
                        Text(domain.title)
                            .font(.besleyBold(Font.title))
                        HStack(spacing: Size.extraSmall) {
                            Text("Browse")
                                .font(.manropeBold(Font.label))
                            Image(systemName: "arrow.right")
                                .font(.system(size: Font.label, weight: .bold))
                        }
                    }
                    .foregroundStyle(Color.background)
                    .padding(Size.medium)
                }
                .bordered(.clear, Radius.card)
        }
    }
    
    private var searchBar: some View {
        HStack(spacing: Size.small) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: Size.iconInline))
                .foregroundStyle(Color.textSecondary)
            
            TextField("Search \(selectedDomain?.title.lowercased() ?? "species")", text: $query)
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
