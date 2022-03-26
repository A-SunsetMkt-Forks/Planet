//
//  PlanetArticleItemView.swift
//  Planet
//
//  Created by Xin Liu on 3/24/22.
//

import SwiftUI

struct PlanetArticleItemView: View {
    @ObservedObject var article: PlanetArticle

    var body: some View {
        HStack {
            VStack {
                Circle()
                    .fill(article.isRead ? Color.clear : Color.blue)
                                .frame(width: 8, height: 8)
                                .padding(.top, 4)
                                .padding(.bottom, 4)
                                .padding(.leading, 4)
                                .padding(.trailing, 4)
                Spacer()
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(article.title ?? "")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                }
                HStack {

                    Text(article.created?.mmddyyyy() ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    

                }
            }
        }
    }
}

/*
struct PlanetArticleItemView_Previews: PreviewProvider {
    static var previews: some View {
        PlanetArticleItemView()
    }
}
*/