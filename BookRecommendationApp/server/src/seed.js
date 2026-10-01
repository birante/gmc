import { fileURLToPath } from 'node:url';
import bcrypt from 'bcryptjs';
import mongoose from 'mongoose';
import Book from './models/Book.js';
import Comment from './models/Comment.js';
import Recommendation from './models/Recommendation.js';
import User from './models/User.js';
import { coverUrl } from './utils/openLibrary.js';

// Catalogue de démo BookNest. ISBN et couvertures vérifiés sur Open Library (coverId = identifiant de couverture).
const BOOKS = [
  { title: "Une si longue lettre", authors: ["Mariama Bâ"], genres: ["Roman", "Littérature africaine"], publishedDate: "1979", pageCount: 120, isbn: "9782842612894", coverId: 14338907, externalId: "ol:/works/OL4672081W", description: "Ramatoulaye, veuve depuis peu, écrit à son amie d'enfance Aïssatou. Une lettre-roman bouleversante sur la condition des femmes, la polygamie et l'amitié dans le Sénégal post-indépendance." },
  { title: "L'Aventure ambiguë", authors: ["Cheikh Hamidou Kane"], genres: ["Roman", "Littérature africaine", "Philosophie"], publishedDate: "1961", pageCount: 205, isbn: "", coverId: 978613, externalId: "ol:/works/OL1015337W", description: "Samba Diallo, enfant de la noblesse diallobé, est envoyé à l'école des Blancs. Un récit initiatique sur le déchirement entre deux cultures et la quête spirituelle." },
  { title: "Chants d'ombre", authors: ["Léopold Sédar Senghor"], genres: ["Poésie", "Littérature africaine"], publishedDate: "1945", pageCount: 78, isbn: "", coverId: 13171268, externalId: "ol:/works/OL10340172W", description: "Le premier recueil de Senghor : la nostalgie du royaume d'enfance à Joal, l'exil parisien et l'affirmation de la Négritude, dans une langue ample et rythmée." },
  { title: "Les Bouts de bois de Dieu", authors: ["Ousmane Sembène"], genres: ["Roman", "Littérature africaine", "Histoire"], publishedDate: "1960", pageCount: 333, isbn: "9782266106313", coverId: 5428280, externalId: "ol:/works/OL1407863W", description: "1947-1948 : la grève des cheminots du Dakar-Niger paralyse la ligne. Sembène raconte la lutte collective, et surtout le rôle décisif des femmes dans la marche vers Dakar." },
  { title: "Le Mandat", authors: ["Ousmane Sembène"], genres: ["Roman", "Littérature africaine"], publishedDate: "1966", pageCount: 190, isbn: "9782708701700", coverId: 983999, externalId: "ol:/works/OL8114719W", description: "Ibrahima Dieng, chômeur dakarois, reçoit un mandat de son neveu parti à Paris. Pour l'encaisser, il lui faut une carte d'identité... Une satire mordante de la bureaucratie et des parasites." },
  { title: "Le Ventre de l'Atlantique", authors: ["Fatou Diome"], genres: ["Roman", "Littérature africaine"], publishedDate: "2003", pageCount: 272, isbn: "9782253109075", coverId: 900782, externalId: "ol:/works/OL9037402W", description: "Salie vit à Strasbourg ; son petit frère Madické, resté sur l'île de Niodior, rêve de football et de France. Un roman tendre et lucide sur le mirage de l'émigration." },
  { title: "La plus secrète mémoire des hommes", authors: ["Mohamed Mbougar Sarr"], genres: ["Roman", "Littérature africaine"], publishedDate: "2021", pageCount: 448, isbn: "9782848768861", coverId: 11273244, externalId: "ol:/works/OL24607185W", description: "Diégane Latyr Faye, jeune écrivain sénégalais à Paris, part sur les traces de T.C. Elimane, auteur d'un chef-d'œuvre maudit disparu en 1938. Prix Goncourt 2021." },
  { title: "La Grève des bàttu", authors: ["Aminata Sow Fall"], genres: ["Roman", "Littérature africaine"], publishedDate: "1979", pageCount: 118, isbn: "9782268068794", coverId: 12509751, externalId: "ol:/works/OL3075656W", description: "Pour « nettoyer » la ville, un ministre fait chasser les mendiants de Dakar. Mais quand ceux-ci se mettent en grève, qui recevra les aumônes indispensables à sa carrière ?" },
  { title: "Murambi, le livre des ossements", authors: ["Boubacar Boris Diop"], genres: ["Roman", "Littérature africaine", "Histoire"], publishedDate: "2000", pageCount: 224, isbn: "9782843045509", coverId: 1153382, externalId: "ol:/works/OL1699936W", description: "Cornelius revient au Rwanda après le génocide des Tutsi et découvre le rôle de son propre père. Un roman polyphonique, grave et nécessaire, sur la mémoire de 1994." },
  { title: "Le Baobab fou", authors: ["Ken Bugul"], genres: ["Roman", "Littérature africaine", "Biographie"], publishedDate: "1982", pageCount: 183, isbn: "9782708708037", coverId: 984780, externalId: "ol:/works/OL2567069W", description: "Récit autobiographique d'une jeune Sénégalaise partie étudier en Belgique : solitude, désillusions et quête d'identité, avec une franchise qui fit scandale à sa sortie." },
  { title: "Le monde s’effondre", authors: ["Chinua Achebe"], genres: ["Roman", "Littérature africaine", "Classique"], publishedDate: "1958", pageCount: 192, isbn: "9782708701915", coverId: 12816943, externalId: "ol:/works/OL891786W", description: "Okonkwo, guerrier respecté d'un village igbo, voit son monde vaciller avec l'arrivée des missionnaires et de l'administration coloniale. Le grand classique du roman africain anglophone." },
  { title: "Décoloniser l'esprit", authors: ["Ngũgĩ wa Thiong'o"], genres: ["Essai", "Littérature africaine"], publishedDate: "1986", pageCount: 128, isbn: "9786059556521", coverId: 14346706, externalId: "ol:/works/OL7986924W", description: "Pourquoi l'écrivain kényan a cessé d'écrire en anglais pour le gikuyu : un essai fondateur sur la langue, l'école coloniale et la libération culturelle." },
  { title: "Americanah", authors: ["Chimamanda Ngozi Adichie"], genres: ["Roman", "Littérature africaine"], publishedDate: "2013", pageCount: 592, isbn: "9782070468805", coverId: 8474037, externalId: "ol:/works/OL16805415W", description: "Ifemelu quitte Lagos pour les États-Unis, où elle découvre ce que signifie être noire en Amérique et tient un blog remarqué. Une histoire d'amour et d'exil, drôle et acérée." },
  { title: "L'Autre Moitié du soleil", authors: ["Chimamanda Ngozi Adichie"], genres: ["Roman", "Littérature africaine", "Histoire"], publishedDate: "2006", pageCount: 500, isbn: "9782070776108", coverId: 8472660, externalId: "ol:/works/OL5731542W", description: "Les années 1960 au Nigeria : deux sœurs jumelles, un professeur engagé et un jeune domestique pris dans la tourmente de la guerre du Biafra." },
  { title: "Les Soleils des indépendances", authors: ["Ahmadou Kourouma"], genres: ["Roman", "Littérature africaine", "Classique"], publishedDate: "1968", pageCount: 204, isbn: "", coverId: 13272075, externalId: "ol:/works/OL661945W", description: "Fama, dernier prince malinké déchu, erre dans une Côte d'Ivoire indépendante qui n'a plus besoin de lui. Un français pétri de malinké, ironique et flamboyant." },
  { title: "Allah n'est pas obligé", authors: ["Ahmadou Kourouma"], genres: ["Roman", "Littérature africaine"], publishedDate: "2000", pageCount: 224, isbn: "9782020525718", coverId: 167482, externalId: "ol:/works/OL661946W", description: "Birahima, enfant-soldat d'une dizaine d'années, raconte avec une gouaille terrible les guerres tribales du Liberia et de la Sierra Leone. Prix Renaudot 2000." },
  { title: "Frère d'âme", authors: ["David Diop"], genres: ["Roman", "Littérature africaine", "Histoire"], publishedDate: "2018", pageCount: 160, isbn: "9782021398243", coverId: 10112533, externalId: "ol:/works/OL20812009W", description: "Alfa Ndiaye, tirailleur sénégalais dans les tranchées de 14-18, perd son ami d'enfance et sombre dans une folie vengeresse. Un monologue halluciné, prix Goncourt des lycéens." },
  { title: "Nations nègres et culture", authors: ["Cheikh Anta Diop"], genres: ["Histoire", "Essai", "Littérature africaine"], publishedDate: "1954", pageCount: 532, isbn: "9782708706880", coverId: 2160646, externalId: "ol:/works/OL2335917W", description: "L'ouvrage fondateur de l'historien sénégalais, qui défend l'antériorité des civilisations africaines et la parenté entre l'Égypte ancienne et l'Afrique noire." },
  { title: "Cahier d'un retour au pays natal", authors: ["Aimé Césaire"], genres: ["Poésie", "Classique"], publishedDate: "1939", pageCount: 128, isbn: "9782760124134", coverId: 12938817, externalId: "ol:/works/OL8302639W", description: "Le long poème inaugural de la Négritude : un cri de révolte et de réconciliation avec la Martinique natale, d'une puissance verbale inégalée." },
  { title: "L'Étranger", authors: ["Albert Camus"], genres: ["Roman", "Classique"], publishedDate: "1942", pageCount: 143, isbn: "9782040120924", coverId: 13151269, externalId: "ol:/works/OL1230613W", description: "Meursault, employé de bureau à Alger, apprend la mort de sa mère avec une indifférence qui déroute. Un été brûlant, un coup de feu sur une plage, puis un procès où l'on juge moins l'acte que l'homme." },
  { title: "La Peste", authors: ["Albert Camus"], genres: ["Roman", "Classique", "Philosophie"], publishedDate: "1947", pageCount: 278, isbn: "9782070360420", coverId: 13151272, externalId: "ol:/works/OL1230715W", description: "Oran, années 1940 : la peste s'abat sur la ville, bientôt coupée du monde. Le docteur Rieux et quelques hommes de bonne volonté s'organisent. Une chronique de la solidarité face à l'absurde." },
  { title: "Le Petit Prince", authors: ["Antoine de Saint-Exupéry"], genres: ["Jeunesse", "Classique", "Philosophie"], publishedDate: "1943", pageCount: 96, isbn: "9782070541935", coverId: 10708272, externalId: "ol:/works/OL10263W", description: "Un aviateur en panne dans le désert du Sahara rencontre un petit prince venu d'une autre planète. Une fable poétique sur l'amitié, l'amour et le regard des enfants sur le monde des grandes personnes." },
  { title: "Les Misérables", authors: ["Victor Hugo"], genres: ["Classique", "Roman", "Histoire"], publishedDate: "1862", isbn: "9782848300443", coverId: 12721865, externalId: "ol:/works/OL1063588W", description: "Jean Valjean, ancien forçat, tente de se racheter face à l'implacable inspecteur Javert. Une épopée sur la justice, la misère et la rédemption dans la France du XIXe siècle." },
  { title: "Madame Bovary", authors: ["Gustave Flaubert"], genres: ["Classique", "Roman"], publishedDate: "1857", pageCount: 351, isbn: "9782070403523", coverId: 12993424, externalId: "ol:/works/OL893707W", description: "Emma, épouse d'un médecin de campagne, s'ennuie et rêve d'une vie de roman. Adultères, dettes et désillusions : le chef-d'œuvre du réalisme français." },
  { title: "Le Comte de Monte-Cristo", authors: ["Alexandre Dumas"], genres: ["Classique", "Roman", "Aventure"], publishedDate: "1844", isbn: "9782070109791", coverId: 14566393, externalId: "ol:/works/OL36287W", description: "Trahi le jour de ses fiançailles, Edmond Dantès passe quatorze ans au château d'If. Évadé et immensément riche, il revient sous un nouveau nom pour se venger." },
  { title: "Germinal", authors: ["Émile Zola"], genres: ["Classique", "Roman"], publishedDate: "1885", pageCount: 498, isbn: "9782891330947", coverId: 8236935, externalId: "ol:/works/OL118986W", description: "Étienne Lantier arrive au coron de Montsou et découvre la misère des mineurs. Il mène une grève qui tourne à l'affrontement. Le grand roman social de Zola." },
  { title: "L'Alchimiste", authors: ["Paulo Coelho"], genres: ["Roman", "Philosophie"], publishedDate: "1988", pageCount: 197, isbn: "9782290258064", coverId: 7414780, externalId: "ol:/works/OL796465W", description: "Santiago, jeune berger andalou, part à la recherche d'un trésor enfoui au pied des pyramides. Un conte initiatique sur l'écoute de son cœur et la Légende Personnelle." },
  { title: "Dune", authors: ["Frank Herbert"], genres: ["Science-fiction"], publishedDate: "1965", pageCount: 608, isbn: "9782266307307", coverId: 11481354, externalId: "ol:/works/OL893414W", description: "Sur Arrakis, planète désertique et unique source de l'Épice, le jeune Paul Atréides doit survivre aux complots qui ont décimé sa famille. Un monument de la science-fiction." },
  { title: "1984", authors: ["George Orwell"], genres: ["Science-fiction", "Classique"], publishedDate: "1949", pageCount: 318, isbn: "9782072938221", coverId: 9267242, externalId: "ol:/works/OL1168083W", description: "Big Brother vous regarde. Winston Smith, employé du ministère de la Vérité, rêve de liberté dans un monde où la pensée elle-même est surveillée." },
  { title: "Fondation", authors: ["Isaac Asimov"], genres: ["Science-fiction"], publishedDate: "1951", pageCount: 240, isbn: "9782070360536", coverId: 14612610, externalId: "ol:/works/OL46125W", description: "Le mathématicien Hari Seldon prédit la chute de l'Empire galactique. Pour abréger l'ère de barbarie qui suivra, il crée la Fondation." },
  { title: "Le Meilleur des mondes", authors: ["Aldous Huxley"], genres: ["Science-fiction", "Classique"], publishedDate: "1932", pageCount: 240, isbn: "9782266283038", coverId: 8231823, externalId: "ol:/works/OL64365W", description: "Dans un futur où les humains sont conçus en éprouvette et conditionnés au bonheur, Bernard Marx doute. Une dystopie visionnaire sur le confort et le contrôle." },
  { title: "Fahrenheit 451", authors: ["Ray Bradbury"], genres: ["Science-fiction", "Classique"], publishedDate: "1953", pageCount: 188, isbn: "9782072892950", coverId: 12993656, externalId: "ol:/works/OL103123W", description: "Montag est pompier : son métier est de brûler les livres, interdits. Jusqu'au jour où il commence à les lire. Un hymne à la littérature et à la pensée libre." },
  { title: "Le Problème à trois corps", authors: ["Liu Cixin"], genres: ["Science-fiction"], publishedDate: "2008", pageCount: 417, isbn: "9782330070748", coverId: 9157544, externalId: "ol:/works/OL17267881W", description: "Pendant la Révolution culturelle, un projet militaire secret envoie un signal vers les étoiles. Des décennies plus tard, une physicienne découvre qu'il a reçu une réponse." },
  { title: "Le Crime de l'Orient-Express", authors: ["Agatha Christie"], genres: ["Policier", "Classique"], publishedDate: "1934", pageCount: 240, isbn: "9782253027676", coverId: 11100465, externalId: "ol:/works/OL471576W", description: "Bloqué par la neige en pleine Yougoslavie, l'Orient-Express abrite un cadavre et douze suspects. Hercule Poirot mène l'une de ses enquêtes les plus célèbres." },
  { title: "Millénium 1 : Les hommes qui n'aimaient pas les femmes", authors: ["Stieg Larsson"], genres: ["Policier", "Thriller"], publishedDate: "2005", pageCount: 576, isbn: "9782298010145", coverId: 9274740, externalId: "ol:/works/OL5784622W", description: "Le journaliste Mikael Blomkvist et la hackeuse Lisbeth Salander enquêtent sur une disparition vieille de quarante ans au sein d'une riche famille suédoise." },
  { title: "Le Chien des Baskerville", authors: ["Arthur Conan Doyle"], genres: ["Policier", "Classique"], publishedDate: "1902", pageCount: 207, isbn: "9782266152501", coverId: 8063264, externalId: "ol:/works/OL262454W", description: "Une malédiction familiale, un chien monstrueux sur la lande du Devon : Sherlock Holmes et le docteur Watson affrontent leur affaire la plus inquiétante." },
  { title: "Sapiens : Une brève histoire de l’humanité", authors: ["Yuval Noah Harari"], genres: ["Histoire", "Essai"], publishedDate: "2011", pageCount: 456, isbn: "9782226257017", coverId: 8634250, externalId: "ol:/works/OL17075811W", description: "Comment Homo sapiens a-t-il conquis la planète ? Révolution cognitive, agricole, scientifique : une fresque ambitieuse de l'histoire de notre espèce." },
  { title: "Le Deuxième Sexe", authors: ["Simone de Beauvoir"], genres: ["Essai", "Philosophie"], publishedDate: "1949", pageCount: 728, isbn: "9782070323524", coverId: 78169, externalId: "ol:/works/OL767941W", description: "« On ne naît pas femme : on le devient. » L'analyse magistrale de la condition féminine qui a nourri tout le féminisme de la seconde moitié du XXe siècle." },
  { title: "Peau noire, masques blancs", authors: ["Frantz Fanon"], genres: ["Essai", "Philosophie"], publishedDate: "1952", pageCount: 232, isbn: "9782757841686", coverId: 482467, externalId: "ol:/works/OL1323771W", description: "Psychiatre martiniquais, Fanon dissèque l'aliénation produite par le racisme colonial, de la langue au désir. Un texte brûlant, toujours étudié." },
  { title: "Le Monde de Sophie", authors: ["Jostein Gaarder"], genres: ["Philosophie", "Roman", "Jeunesse"], publishedDate: "1991", pageCount: 557, isbn: "9782020326193", coverId: 964589, externalId: "ol:/works/OL922425W", description: "Sophie, quatorze ans, reçoit d'étranges lettres : « Qui es-tu ? », « D'où vient le monde ? ». Un roman qui fait voyager à travers toute l'histoire de la philosophie." },
  { title: "Les 7 habitudes de ceux qui réalisent tout ce qu’ils entreprennent", authors: ["Stephen R. Covey"], genres: ["Développement personnel"], publishedDate: "1989", pageCount: 374, isbn: "9781797115092", coverId: 10079937, externalId: "ol:/works/OL2629977W", description: "Proactivité, vision à long terme, priorités, écoute : sept principes pour gagner en efficacité personnelle et dans ses relations. Un best-seller mondial." },
  { title: "Un rien peut tout changer", authors: ["James Clear"], genres: ["Développement personnel"], publishedDate: "2018", pageCount: 323, isbn: "9782035969200", coverId: 12539702, externalId: "ol:/works/OL17930368W", description: "Les petites habitudes, répétées chaque jour, produisent des effets énormes. Une méthode concrète pour installer de bonnes habitudes et se débarrasser des mauvaises." },
  { title: "Harry Potter à l'école des sorciers", authors: ["J. K. Rowling"], genres: ["Jeunesse", "Fantasy"], publishedDate: "1997", pageCount: 302, isbn: "9782070619177", coverId: 15155833, externalId: "ol:/works/OL82563W", description: "Le jour de ses onze ans, Harry apprend qu'il est un sorcier et entre à Poudlard. Amitié, magie et premier affrontement avec celui-dont-on-ne-doit-pas-prononcer-le-nom." },
  { title: "Le Petit Nicolas", authors: ["René Goscinny", "Jean-Jacques Sempé"], genres: ["Jeunesse", "Humour"], publishedDate: "1959", pageCount: 155, isbn: "9782070524273", coverId: 12856967, externalId: "ol:/works/OL2383558W", description: "Les bêtises de Nicolas et de ses copains Alceste, Geoffroy ou Clotaire, racontées à hauteur d'enfant. Un classique tendre et drôle, illustré par Sempé." },
  { title: "Astérix le Gaulois", authors: ["René Goscinny", "Albert Uderzo"], genres: ["Bande dessinée", "Humour"], publishedDate: "1961", pageCount: 48, isbn: "9782012101333", coverId: 962725, externalId: "ol:/works/OL267622W", description: "Nous sommes en 50 avant J.-C. Toute la Gaule est occupée... Toute ? Non ! Un village d'irréductibles Gaulois résiste encore grâce à la potion magique. Le premier album." },
  { title: "Persepolis", authors: ["Marjane Satrapi"], genres: ["Bande dessinée", "Biographie", "Histoire"], publishedDate: "2000", pageCount: 352, isbn: "9782844141040", coverId: 12648921, externalId: "ol:/works/OL5735175W", description: "Marjane grandit à Téhéran pendant la révolution islamique puis la guerre Iran-Irak. Un récit autobiographique en noir et blanc, à la fois drôle et poignant." },
  { title: "Aya de Yopougon", authors: ["Marguerite Abouet", "Clément Oubrerie"], genres: ["Bande dessinée", "Littérature africaine", "Humour"], publishedDate: "2005", pageCount: 128, isbn: "9782070619955", coverId: 10869888, externalId: "ol:/works/OL24346207W", description: "Abidjan, fin des années 1970. Aya, 19 ans, rêve de devenir médecin tandis que ses copines préfèrent les maquis et les garçons. Une chronique pétillante de la Côte d'Ivoire." },
  { title: "Clean Code", authors: ["Robert C. Martin"], genres: ["Informatique", "Programmation"], publishedDate: "2008", pageCount: 444, isbn: "9782326002890", coverId: 8065615, externalId: "ol:/works/OL17618370W", description: "Nommage, fonctions courtes, tests, refactoring : les principes d'artisanat logiciel pour écrire un code lisible et maintenable, illustrés par de nombreux exemples." },
  { title: "The Pragmatic Programmer", authors: ["Andrew Hunt", "David Thomas"], genres: ["Informatique", "Programmation"], publishedDate: "1999", pageCount: 352, isbn: "9788131722428", coverId: 10143650, externalId: "ol:/works/OL5748544W", description: "De la responsabilité du développeur à l'automatisation, en passant par le DRY et les « tracer bullets » : des conseils concrets pour progresser dans le métier." },
  { title: "Eloquent JavaScript", authors: ["Marijn Haverbeke"], genres: ["Informatique", "Programmation"], publishedDate: "2011", pageCount: 446, isbn: "9781593279509", coverId: 7082166, externalId: "ol:/works/OL15444205W", description: "Une introduction moderne à la programmation et au langage JavaScript : bases, fonctions d'ordre supérieur, asynchronisme, navigateur et Node.js, avec des projets pratiques." },
];

const USERS = [
  { username: 'amina', email: 'amina@booknest.app', bio: 'Dakaroise, grande lectrice de littérature africaine et de classiques.', favoriteGenres: ['Littérature africaine', 'Classique', 'Roman'] },
  { username: 'lucas', email: 'lucas@booknest.app', bio: 'Ingénieur le jour, explorateur de galaxies lointaines la nuit.', favoriteGenres: ['Science-fiction', 'Essai', 'Informatique'] },
  { username: 'sofia', email: 'sofia@booknest.app', bio: 'Prof de philo, je recommande les livres qui font réfléchir.', favoriteGenres: ['Philosophie', 'Histoire', 'Jeunesse'] },
];

// [utilisateur, titre du livre, note, avis, il y a N heures, likers, commentaires]
const RECS = [
  ['amina', 'Une si longue lettre', 5, "Un chef-d'œuvre. Chaque phrase est d'une justesse incroyable sur la condition des femmes. À lire absolument.", 6, ['sofia', 'lucas'], [['sofia', "Je l'ai fait lire à mes élèves, ils ont adoré !"]]],
  ['amina', "L'Aventure ambiguë", 5, "Le dilemme de Samba Diallo est toujours d'actualité. Une écriture d'une grande beauté, presque méditative.", 40, ['sofia'], []],
  ['amina', 'La plus secrète mémoire des hommes', 5, 'Un roman-labyrinthe vertigineux sur la littérature elle-même. Mbougar Sarr mérite cent fois son Goncourt.', 2, ['lucas', 'sofia'], [['lucas', "Il est dans ma pile, tu me donnes envie de l'attaquer."], ['amina', 'Prévois du temps, on ne le lâche plus.']]],
  ['amina', 'Les Bouts de bois de Dieu', 4, 'Une fresque collective puissante. Les personnages féminins, Penda en tête, sont inoubliables.', 90, ['sofia'], []],
  ['amina', "Le Ventre de l'Atlantique", 4, "Drôle et mélancolique à la fois : le Niodior de Fatou Diome m'a rappelé tant de conversations familiales.", 160, [], []],
  ['amina', "L'Étranger", 4, 'Court, sec, et pourtant inoubliable. Camus en pleine forme.', 120, ['lucas'], [['lucas', "La scène de la plage m'a marqué."]]],
  ['amina', 'Americanah', 5, "Ifemelu est l'une des héroïnes les plus vivantes que j'aie lues. Et les billets de blog sont savoureux.", 26, ['sofia'], []],
  ['lucas', 'Dune', 5, "Le meilleur roman de SF jamais écrit. L'écologie, la politique, la religion... tout y est.", 3, ['amina', 'sofia'], [['amina', "Tu m'as convaincue, je le commence ce week-end !"], ['lucas', 'Accroche-toi pour les 100 premières pages, ça vaut le coup.']]],
  ['lucas', 'Fondation', 4, "Une saga d'idées plus que d'action, mais quelle ambition intellectuelle.", 72, [], []],
  ['lucas', '1984', 5, 'Glaçant et plus pertinent que jamais à l’ère des réseaux sociaux.', 200, ['sofia'], []],
  ['lucas', 'Le Problème à trois corps', 4, 'Démarrage lent, puis des idées physiques folles. La partie sur la Révolution culturelle est saisissante.', 14, ['amina'], []],
  ['lucas', 'Clean Code', 4, 'Certains conseils ont vieilli, mais le chapitre sur le nommage devrait être obligatoire pour tout développeur.', 50, [], [['sofia', 'Même pour une philosophe, le nommage est une affaire sérieuse !']]],
  ['lucas', 'The Pragmatic Programmer', 5, 'Le livre que je relis tous les deux ans. Concret, humble, plein de bon sens.', 300, ['amina'], []],
  ['lucas', "Allah n'est pas obligé", 5, "Recommandé par Amina, et quelle claque. La voix de Birahima est terrible et drôle à la fois.", 20, ['amina'], [['amina', "Content que ça t'ait plu ! Lis Les Soleils des indépendances ensuite."]]],
  ['sofia', 'Le Monde de Sophie', 5, 'Parfait pour découvrir la philosophie sans s’ennuyer. Je le conseille à tous mes élèves.', 10, ['amina'], [['amina', 'Un classique de mon adolescence !']]],
  ['sofia', 'Le Petit Prince', 5, "On l'apprivoise à chaque relecture. « On ne voit bien qu'avec le cœur. »", 30, ['amina', 'lucas'], []],
  ['sofia', 'Sapiens : Une brève histoire de l’humanité', 4, 'Stimulant et très bien vulgarisé, même si certaines thèses sont discutables.', 96, ['lucas'], []],
  ['sofia', "L'Alchimiste", 3, 'Joli conte, mais un peu trop simple à mon goût. Idéal pour un moment de douceur.', 150, [], []],
  ['sofia', 'Peau noire, masques blancs', 5, 'Un texte exigeant mais essentiel. À lire en parallèle de Senghor et Césaire pour mesurer les débats de la Négritude.', 8, ['amina'], []],
  ['sofia', 'Persepolis', 5, "La meilleure porte d'entrée vers l'histoire de l'Iran. Mes élèves de terminale l'ont dévoré.", 60, ['lucas', 'amina'], []],
  ['sofia', 'Le Deuxième Sexe', 4, 'Dense, parfois daté, mais fondateur. Le chapitre sur l’enfance reste d’une lucidité étonnante.', 230, [], []],
];

// Votes supplémentaires sans recommandation : [utilisateur, titre, note]
const EXTRA_RATINGS = [
  ['lucas', 'Le Petit Prince', 4],
  ['amina', 'Dune', 4],
  ['amina', 'Les Misérables', 5],
  ['lucas', 'Les Misérables', 4],
  ['sofia', "L'Étranger", 4],
  ['sofia', 'Une si longue lettre', 5],
  ['lucas', 'La plus secrète mémoire des hommes', 4],
  ['sofia', "Chants d'ombre", 5],
  ['amina', "Chants d'ombre", 5],
  ['amina', "Cahier d'un retour au pays natal", 5],
  ['sofia', 'Le monde s’effondre', 4],
  ['amina', 'Le monde s’effondre', 5],
  ['lucas', 'Fahrenheit 451', 4],
  ['sofia', 'Le Meilleur des mondes', 4],
  ['amina', 'Aya de Yopougon', 5],
  ['sofia', 'Astérix le Gaulois', 4],
  ['lucas', "Harry Potter à l'école des sorciers", 4],
  ['amina', 'Les Soleils des indépendances', 4],
  ['lucas', "Le Crime de l'Orient-Express", 4],
  ['sofia', 'La Peste', 5],
];

export const SEED_BOOK_COUNT = BOOKS.length;

export async function seedIfEmpty({ log = true } = {}) {
  const [users, books] = await Promise.all([User.estimatedDocumentCount(), Book.estimatedDocumentCount()]);
  if (users > 0 || books > 0) {
    if (log) console.log('[seed] base non vide, seed ignoré');
    return false;
  }
  const passwordHash = await bcrypt.hash('password123', 10);
  const userDocs = await User.insertMany(USERS.map((u) => ({ ...u, passwordHash })));
  const byName = Object.fromEntries(userDocs.map((u) => [u.username, u]));

  // Graphe social : amina <-> sofia, lucas -> amina
  const follows = [
    ['amina', 'sofia'],
    ['sofia', 'amina'],
    ['lucas', 'amina'],
  ];
  for (const [a, b] of follows) {
    await User.updateOne({ _id: byName[a]._id }, { $addToSet: { following: byName[b]._id } });
    await User.updateOne({ _id: byName[b]._id }, { $addToSet: { followers: byName[a]._id } });
  }

  const bookDocs = await Book.insertMany(
    BOOKS.map(({ coverId, externalId, ...b }, i) => ({
      ...b,
      coverUrl: coverUrl(coverId),
      ...(externalId ? { externalId } : {}),
      source: 'booknest',
      addedBy: userDocs[i % userDocs.length]._id,
    }))
  );
  const byTitle = new Map(bookDocs.map((b) => [b.title, b]));
  const findBook = (title) => {
    const book = byTitle.get(title);
    if (!book) throw new Error(`[seed] livre inconnu : ${title}`);
    return book;
  };

  const now = Date.now();
  for (const [username, title, rating, review, hoursAgo, likers, comments] of RECS) {
    const user = byName[username];
    const book = findBook(title);
    const createdAt = new Date(now - hoursAgo * 3600 * 1000);
    const rec = await Recommendation.create({ user: user._id, book: book._id, rating, review, likes: likers.map((n) => byName[n]._id), createdAt, updatedAt: createdAt });
    book.setUserRating(user._id, rating);
    let t = createdAt.getTime();
    for (const [author, text] of comments) {
      t += 45 * 60 * 1000;
      await Comment.create({ recommendation: rec._id, user: byName[author]._id, text, createdAt: new Date(t), updatedAt: new Date(t) });
    }
  }
  for (const [username, title, value] of EXTRA_RATINGS) findBook(title).setUserRating(byName[username]._id, value);
  await Promise.all(bookDocs.map((b) => b.save()));
  if (log) console.log(`[seed] ${userDocs.length} utilisateurs, ${bookDocs.length} livres, ${RECS.length} recommandations créés (mot de passe : password123)`);
  return true;
}

// Exécution directe : node src/seed.js
if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const uri = process.env.MONGODB_URI || 'mongodb://localhost:27017/booknest';
  mongoose
    .connect(uri)
    .then(() => seedIfEmpty())
    .then(() => mongoose.disconnect())
    .catch((err) => {
      console.error(err);
      process.exit(1);
    });
}
